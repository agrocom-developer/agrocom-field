import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/trabajo_local.dart' show EstadoTrabajoLocal;
import '../domain/reglas_trabajo.dart';
import '../domain/trabajo.dart';

/// Escribe la apertura de un trabajo (`AperturaTrabajo`) y su cierre
/// (`CierreTrabajo`, HU-09) — ver esos contratos en `agrocom-api`: inserta o
/// actualiza [TrabajoLocal] y encola en `ColaSync` en una sola transacción
/// (invariante 3 de CLAUDE.md) — ningún caso de uso espera la red para
/// confirmar en pantalla.
class TrabajoRepository {
  TrabajoRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// [inicio] es un parámetro obligatorio, no `DateTime.now()` interno: eso
  /// mantiene el repositorio testeable con un reloj fijo. Quien lo invoque
  /// (la capa de presentación, otra etapa) le pasa `DateTime.now()`.
  Future<Trabajo> abrirTrabajo({
    required int ordenId,
    required int loteId,
    required int nroAplicacion,
    Decimal? hectareasDeclaradas,
    required DateTime inicio,
  }) {
    final uuidCliente = _uuid.v4();
    final hectareas = hectareasDeclaradas ?? Decimal.parse('0');

    return _db.transaction(() async {
      await _db
          .into(_db.trabajoLocal)
          .insert(
            TrabajoLocalCompanion.insert(
              uuidCliente: uuidCliente,
              ordenId: ordenId,
              loteId: loteId,
              nroAplicacion: nroAplicacion,
              hectareasDeclaradas: Value(hectareas),
              inicio: inicio,
            ),
          );

      final secuencia = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidCliente,
              tipoEntidad: 'trabajo',
              // Sin `tipo`/`uuid_cliente` acá a propósito: viajan por las
              // columnas dedicadas de `ColaSync` y `SyncEngine` las vuelve a
              // inyectar al armar el request (ver
              // `SyncEngine._registroDesdeFila`).
              payload: jsonEncode({
                'orden_id': ordenId,
                'lote_id': loteId,
                'nro_aplicacion': nroAplicacion,
                'hectareas_declaradas': hectareas.toString(),
                'inicio': inicio.toUtc().toIso8601String(),
              }),
              secuencia: secuencia,
            ),
          );

      return Trabajo(
        uuidCliente: uuidCliente,
        ordenId: ordenId,
        loteId: loteId,
        nroAplicacion: nroAplicacion,
        hectareasDeclaradas: hectareas,
        inicio: inicio,
      );
    });
  }

  /// Actualiza la MISMA fila de [TrabajoLocal] con los campos de cierre, sin
  /// tocar `ordenId`/`loteId`/`nroAplicacion`/`hectareasDeclaradas`/`inicio`
  /// de apertura (invariante 6 de CLAUDE.md), y encola `cierre_trabajo` — un
  /// evento nuevo con su propio `uuid_cliente` ([uuidClienteCierre]), nunca
  /// el `uuid_cliente` de apertura del trabajo. Todo dentro de una sola
  /// transacción (invariante 3 de CLAUDE.md) — mismo patrón que
  /// `SesionRepository.cerrarSesion`.
  ///
  /// Lanza [EvidenciaImagenCampoRequeridaExcepcion] ANTES de escribir nada
  /// si [evidenciaImagenCampoUuidCliente] es `null` o está vacío/en blanco
  /// ("sin captura no cierra") — el contrato real (`CierreTrabajo.php` en
  /// `agrocom-api`) solo exige esa evidencia, nunca un segundo campo de
  /// `captura_rc` (no está enganchado a ningún DTO real todavía).
  ///
  /// Sin campo de hectáreas acá a propósito:
  /// `trabajos.hectareas_declaradas` es derivado (suma de sesiones) del
  /// lado servidor, nunca algo que el dispositivo declare al cerrar.
  Future<Trabajo> cerrarTrabajo({
    required String trabajoUuidCliente,
    required DateTime fin,
    Decimal? litrosSobrante,
    required String evidenciaImagenCampoUuidCliente,
  }) async {
    verificarEvidenciaImagenCampo(evidenciaImagenCampoUuidCliente);

    final uuidClienteCierre = _uuid.v4();

    return _db.transaction(() async {
      await (_db.update(
        _db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals(trabajoUuidCliente))).write(
        TrabajoLocalCompanion(
          estado: const Value(EstadoTrabajoLocal.cerrado),
          fin: Value(fin),
          litrosSobrante: Value(litrosSobrante),
          evidenciaImagenCampoUuidCliente: Value(
            evidenciaImagenCampoUuidCliente,
          ),
          uuidClienteCierre: Value(uuidClienteCierre),
        ),
      );

      final secuencia = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidClienteCierre,
              tipoEntidad: 'cierre_trabajo',
              payload: jsonEncode({
                'trabajo_uuid_cliente': trabajoUuidCliente,
                'fin': fin.toUtc().toIso8601String(),
                'litros_sobrante': litrosSobrante?.toString(),
                'evidencia_imagen_campo_uuid_cliente':
                    evidenciaImagenCampoUuidCliente,
              }),
              secuencia: secuencia,
            ),
          );

      final fila = await (_db.select(
        _db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals(trabajoUuidCliente))).getSingle();
      return _trabajoDesdeFila(fila);
    });
  }

  /// Orden causal GLOBAL de todo lo que este dispositivo encola (invariante
  /// 5 de CLAUDE.md) — mezcla trabajos, sesiones, cierres y cualquier otro
  /// tipo futuro. Distinto de `SesionLocal.secuencia`, que es el orden de
  /// apertura de sesión dentro de un trabajo específico.
  Future<int> _proximaSecuenciaGlobal() async {
    final maximo = _db.colaSync.secuencia.max();
    final fila = await (_db.selectOnly(
      _db.colaSync,
    )..addColumns([maximo])).getSingle();
    return (fila.read(maximo) ?? 0) + 1;
  }

  Trabajo _trabajoDesdeFila(TrabajoLocalData fila) {
    return Trabajo(
      uuidCliente: fila.uuidCliente,
      ordenId: fila.ordenId,
      loteId: fila.loteId,
      nroAplicacion: fila.nroAplicacion,
      hectareasDeclaradas: fila.hectareasDeclaradas,
      inicio: fila.inicio,
      estado: fila.estado == EstadoTrabajoLocal.abierto
          ? EstadoTrabajo.abierto
          : EstadoTrabajo.cerrado,
      fin: fila.fin,
      litrosSobrante: fila.litrosSobrante,
      evidenciaImagenCampoUuidCliente: fila.evidenciaImagenCampoUuidCliente,
      uuidClienteCierre: fila.uuidClienteCierre,
    );
  }
}
