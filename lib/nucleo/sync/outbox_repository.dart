import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/tablas/cola_sync.dart';

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
