import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import '../db/database.dart';
import '../db/tablas/evidencia_local.dart' show EstadoEvidenciaLocal;

/// Motor de subida de la cola de evidencias (TE-07) — SEPARADO de
/// `SyncEngine` (invariante 8 de CLAUDE.md: cola de evidencias separada de
/// los registros livianos). A diferencia de `SyncEngine`, que manda el
/// outbox completo en un solo `POST /api/sync`, el contrato de
/// `POST /api/evidencias` es multipart y de a UNA: este motor itera las
/// filas `pendiente` y hace un request por cada una, así que un fallo
/// puntual (red, rechazo) nunca frena la subida de las demás en el mismo
/// ciclo — no hay "abortar el lote" posible acá.
class EvidenciaSyncEngine {
  EvidenciaSyncEngine({required ApiClient apiClient, required AppDatabase db})
    : _apiClient = apiClient,
      _db = db;

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Dispara un ciclo de subida: lee las filas `pendiente` de
  /// [EvidenciaLocal] y sube cada una por separado. Mismo criterio que
  /// `SyncEngine.sincronizar` para decidir el trigger (conectividad
  /// recuperada, apertura de app, botón manual) — acá tampoco hay
  /// temporizadores ni reintentos con backoff, el ciclo corre una sola vez
  /// por llamada.
  Future<void> sincronizar() async {
    final pendientes = await _leerPendientes();
    for (final fila in pendientes) {
      await _subirUna(fila);
    }
  }

  Future<List<EvidenciaLocalData>> _leerPendientes() {
    return (_db.select(_db.evidenciaLocal)
          ..where((t) => t.estado.equalsValue(EstadoEvidenciaLocal.pendiente)))
        .get();
  }

  Future<void> _subirUna(EvidenciaLocalData fila) async {
    final Response<dynamic> respuesta;
    try {
      respuesta = await _apiClient.post(
        '/api/evidencias',
        data: FormData.fromMap({
          'uuid_cliente': fila.uuidCliente,
          'tipo': fila.tipo,
          'fecha': fila.fecha.toUtc().toIso8601String(),
          'hash_dispositivo': fila.hashSha256,
          'archivo': await MultipartFile.fromFile(fila.rutaArchivoLocal),
        }),
      );
    } on ApiExcepcionRed {
      // Sin señal ahora — no es un error del motor (ver api_excepcion.dart):
      // la fila queda `pendiente`, lista para el próximo ciclo.
      return;
    } on ApiExcepcion {
      // Servidor/desconocida: sin una respuesta parseada no hay forma de
      // saber qué decidió el servidor, así que esta fila no se toca. El
      // ciclo SIGUE con las demás pendientes — a diferencia de `SyncEngine`,
      // acá no existe "el lote" que abortar.
      return;
    }

    final cuerpo = respuesta.data as Map<String, dynamic>;
    switch (cuerpo['estado'] as String) {
      case 'aplicado':
      case 'duplicado':
        // `duplicado` (reintento del mismo uuid_cliente) se trata como
        // éxito — mismo vocabulario que `OutboxRepository.marcarConfirmado`.
        await _marcarSubido(fila.uuidCliente);
      case 'rechazado':
        await _marcarRechazado(fila.uuidCliente, cuerpo['motivo'] as String);
    }
  }

  /// Ninguna fila ya `subido` se reescribe (invariante 6 de CLAUDE.md) — el
  /// `where` la excluye aunque este motor procese la misma fila dos veces.
  Future<void> _marcarSubido(String uuidCliente) {
    return _actualizarEstado(
      uuidCliente,
      const EvidenciaLocalCompanion(estado: Value(EstadoEvidenciaLocal.subido)),
    );
  }

  Future<void> _marcarRechazado(String uuidCliente, String motivo) {
    return _actualizarEstado(
      uuidCliente,
      EvidenciaLocalCompanion(
        estado: const Value(EstadoEvidenciaLocal.rechazado),
        motivoRechazo: Value(motivo),
      ),
    );
  }

  Future<void> _actualizarEstado(
    String uuidCliente,
    EvidenciaLocalCompanion cambios,
  ) {
    return (_db.update(_db.evidenciaLocal)..where(
          (t) =>
              t.uuidCliente.equals(uuidCliente) &
              t.estado.equalsValue(EstadoEvidenciaLocal.subido).not(),
        ))
        .write(cambios);
  }
}
