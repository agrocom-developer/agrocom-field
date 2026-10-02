import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/tablas/cola_sync.dart';
import '../db/tablas/evidencia_local.dart' show EstadoEvidenciaLocal;

/// Única pieza de `nucleo/sync` que toca `drift` directamente (invariante 3
/// de CLAUDE.md: escribir es insertar local + encolar en outbox, en una sola
/// transacción — acá solo la parte de lectura/avance de estado del outbox
/// que usa `SyncEngine`, no la inserción inicial, que hace cada feature).
class OutboxRepository {
  OutboxRepository(this._db);

  final AppDatabase _db;

  /// Filas `pendiente`, ordenadas por `secuencia` ascendente — nunca por
  /// `creadoEn` ni por reloj de dispositivo (invariante 5 de CLAUDE.md).
  Future<List<ColaSyncData>> leerPendientes() {
    return (_db.select(_db.colaSync)
          ..where((t) => t.estado.equalsValue(EstadoSync.pendiente))
          ..orderBy([(t) => OrderingTerm.asc(t.secuencia)]))
        .get();
  }

  /// Filas `pendiente` listas para enviar: [leerPendientes] menos las que
  /// referencian una evidencia que todavía no se subió.
  ///
  /// El servidor rechaza un registro cuya evidencia todavía no recibió
  /// (`falta_imagen_campo` en `cierre_trabajo`, y lo mismo con la foto de una
  /// incidencia), y un rechazo es definitivo en el outbox: la fila no se
  /// vuelve a mandar. Como el ciclo empuja el outbox antes de subir las
  /// evidencias (`DisparadorSync`), un cierre cargado sin señal viajaba
  /// antes que su foto y se perdía. Retenida acá, la fila sigue `pendiente`
  /// y sale en el primer ciclo después de que su evidencia quede `subido`.
  ///
  /// Una evidencia `rechazado` o que no está en `evidencia_local` no retiene
  /// nada: esperar no la va a subir, así que el registro sale y el servidor
  /// decide. Retener solo esas filas, y no todo lo que viene detrás, no rompe
  /// el orden causal (invariante 5): ningún registro de hoy referencia a un
  /// `cierre_trabajo` ni a una incidencia.
  Future<List<ColaSyncData>> leerListasParaEnviar() async {
    final pendientes = await leerPendientes();
    final evidenciasSinSubir =
        (await (_db.selectOnly(_db.evidenciaLocal)
                  ..addColumns([_db.evidenciaLocal.uuidCliente])
                  ..where(
                    _db.evidenciaLocal.estado.equalsValue(
                      EstadoEvidenciaLocal.pendiente,
                    ),
                  ))
                .get())
            .map((fila) => fila.read(_db.evidenciaLocal.uuidCliente)!)
            .toSet();
    if (evidenciasSinSubir.isEmpty) return pendientes;
    return pendientes
        .where(
          (fila) =>
              !_evidenciasReferenciadas(fila).any(evidenciasSinSubir.contains),
        )
        .toList();
  }

  /// `uuid_cliente` de evidencias que referencia el payload de [fila]: todo
  /// campo `evidencia_*_uuid_cliente` del registro (hoy,
  /// `evidencia_imagen_campo_uuid_cliente` del cierre de trabajo y
  /// `evidencia_foto_uuid_cliente` de la incidencia).
  static Iterable<String> _evidenciasReferenciadas(ColaSyncData fila) {
    final payload = jsonDecode(fila.payload);
    if (payload is! Map<String, dynamic>) return const [];
    return payload.entries
        .where(
          (campo) =>
              campo.key.startsWith('evidencia_') &&
              campo.key.endsWith('_uuid_cliente') &&
              campo.value is String,
        )
        .map((campo) => campo.value as String);
  }

  /// Marca la fila de [uuidCliente] como `confirmado` (respuesta `aplicado`
  /// o `duplicado` del servidor — invariante 5 de `docs/vision.md`: un
  /// duplicado se trata como éxito).
  Future<void> marcarConfirmado(String uuidCliente) {
    return _actualizarEstado(
      uuidCliente,
      const ColaSyncCompanion(estado: Value(EstadoSync.confirmado)),
    );
  }

  /// Marca la fila de [uuidCliente] como `rechazado`, con su [motivo].
  Future<void> marcarRechazado(String uuidCliente, String motivo) {
    return _actualizarEstado(
      uuidCliente,
      ColaSyncCompanion(
        estado: const Value(EstadoSync.rechazado),
        motivoRechazo: Value(motivo),
      ),
    );
  }

  /// Ninguna fila ya `confirmado` se reescribe (invariante 6 de CLAUDE.md) —
  /// el `where` la excluye aunque alguien llame este método por error dos
  /// veces para el mismo `uuidCliente`.
  Future<void> _actualizarEstado(
    String uuidCliente,
    ColaSyncCompanion cambios,
  ) {
    return (_db.update(_db.colaSync)..where(
          (t) =>
              t.uuidCliente.equals(uuidCliente) &
              t.estado.equalsValue(EstadoSync.confirmado).not(),
        ))
        .write(cambios);
  }
}
