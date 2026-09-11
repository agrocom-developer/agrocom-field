import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/db/database.dart';
import '../domain/trabajo.dart';

/// Escribe la apertura de un trabajo (`AperturaTrabajo`, ver
/// `AperturaTrabajo.php` en `agrocom-api`): inserta [TrabajoLocal] y encola
/// en `ColaSync` en una sola transacción (invariante 3 de CLAUDE.md) —
/// ningún caso de uso espera la red para confirmar en pantalla.
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
}
