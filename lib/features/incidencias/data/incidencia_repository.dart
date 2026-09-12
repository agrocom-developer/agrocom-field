import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/sesion_local.dart' show EstadoSesionLocal;
import '../../../nucleo/evidencias/evidencia_repository.dart';
import '../domain/incidencia.dart';
import '../domain/reglas_incidencia.dart';
import '../domain/tipo_incidencia.dart';

/// Registra una incidencia (`RegistroIncidencia`, HU-08): valida que la
/// sesión exista y esté abierta ANTES de comprimir/persistir la foto (no
/// tiene sentido gastar la captura si la sesión no es válida — mismo
/// criterio que `SesionRepository.verificarTrabajoExiste`), captura la
/// evidencia vía [EvidenciaRepository] (que ya resuelve su propia cola,
/// invariante 8 de CLAUDE.md) y con el `uuid_cliente` que devuelve arma el
/// insert de [IncidenciaLocal] + el encolado en `ColaSync` en una sola
/// transacción (invariante 3 de CLAUDE.md) — mismo patrón que
/// `TrabajoRepository`/`SesionRepository`.
class IncidenciaRepository {
  IncidenciaRepository(
    this._db, {
    required EvidenciaRepository evidenciaRepository,
    Uuid? uuid,
  }) : _evidenciaRepository = evidenciaRepository,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final EvidenciaRepository _evidenciaRepository;
  final Uuid _uuid;

  /// Lanza [SesionInexistenteExcepcion] o [SesionCerradaExcepcion] ANTES de
  /// comprimir/persistir [bytesFoto] ni escribir nada (ni [IncidenciaLocal]
  /// ni `ColaSync`). [hora] es obligatoria, no `DateTime.now()` interno, por
  /// el mismo motivo que en `TrabajoRepository.abrirTrabajo`.
  Future<Incidencia> registrarIncidencia({
    required String sesionUuidCliente,
    required TipoIncidencia tipo,
    String? descripcion,
    required DateTime hora,
    required Uint8List bytesFoto,
  }) async {
    final sesion = await _sesionPorUuid(sesionUuidCliente);
    verificarSesionActiva(
      sesionExiste: sesion != null,
      sesionAbierta: sesion?.estado == EstadoSesionLocal.abierta,
      sesionUuidCliente: sesionUuidCliente,
    );

    final evidenciaFotoUuidCliente = await _evidenciaRepository
        .capturarEvidencia(
          bytesOriginales: bytesFoto,
          tipo: 'foto_incidencia',
          fecha: hora,
        );

    final uuidCliente = _uuid.v4();

    return _db.transaction(() async {
      await _db
          .into(_db.incidenciaLocal)
          .insert(
            IncidenciaLocalCompanion.insert(
              uuidCliente: uuidCliente,
              sesionUuidCliente: sesionUuidCliente,
              tipo: tipo.name,
              descripcion: Value(descripcion),
              hora: hora,
              evidenciaFotoUuidCliente: evidenciaFotoUuidCliente,
            ),
          );

      final secuencia = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidCliente,
              tipoEntidad: 'incidencia',
              // `tipo_incidencia`, NUNCA `tipo` a secas: esa key ya
              // distingue el TIPO DE REGISTRO del lote — ver el prompt de
              // esta tarea y `RegistroIncidencia.php` en `agrocom-api`.
              payload: jsonEncode({
                'sesion_uuid_cliente': sesionUuidCliente,
                'tipo_incidencia': tipo.name,
                'descripcion': descripcion,
                'hora': hora.toUtc().toIso8601String(),
                'evidencia_foto_uuid_cliente': evidenciaFotoUuidCliente,
              }),
              secuencia: secuencia,
            ),
          );

      return Incidencia(
        uuidCliente: uuidCliente,
        sesionUuidCliente: sesionUuidCliente,
        tipo: tipo,
        descripcion: descripcion,
        hora: hora,
        evidenciaFotoUuidCliente: evidenciaFotoUuidCliente,
      );
    });
  }

  Future<SesionLocalData?> _sesionPorUuid(String sesionUuidCliente) {
    return (_db.select(
      _db.sesionLocal,
    )..where((t) => t.uuidCliente.equals(sesionUuidCliente))).getSingleOrNull();
  }

  /// Ver el mismo comentario en `TrabajoRepository._proximaSecuenciaGlobal`
  /// — se duplica a propósito (CLAUDE.md: no crear una abstracción
  /// compartida nueva solo para esto).
  Future<int> _proximaSecuenciaGlobal() async {
    final maximo = _db.colaSync.secuencia.max();
    final fila = await (_db.selectOnly(
      _db.colaSync,
    )..addColumns([maximo])).getSingle();
    return (fila.read(maximo) ?? 0) + 1;
  }
}
