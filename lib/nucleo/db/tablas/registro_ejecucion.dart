import 'package:drift/drift.dart';

/// Vocabulario de la cola liviana de la ejecución: `pendiente → confirmado |
/// rechazado`. Lo mueve `EjecucionSyncEngine`; `confirmado` y `rechazado` los
/// decide siempre el servidor.
enum EstadoRegistroEjecucion { pendiente, confirmado, rechazado }

/// Outbox liviano de la ejecución de un servicio adjudicado: marcar el inicio
/// (`inicio`), el avance (`avance`) y el cierre (`cierre`) sin señal
/// (ADR 0016). Cada fila es a la vez el registro local y su entrada en la
/// cola: se inserta junto con la actualización del espejo, en una sola
/// transacción (invariante 3 de CLAUDE.md).
///
/// Es una cola aparte de `cola_sync`: esos registros viajan en lote a
/// `POST /api/sync` y estos van uno por uno a los endpoints de la solicitud
/// (`/api/solicitudes/{id}/inicio|avance|cierre`), idempotentes por
/// `uuid_cliente`. Las fotos van en `foto_ejecucion` (invariante 8).
class RegistroEjecucion extends Table {
  /// Generado en el dispositivo antes de tocar la red (invariante 2) y
  /// conservado entre reintentos.
  TextColumn get uuidCliente => text()();

  IntColumn get solicitudId => integer()();

  /// `inicio`, `avance` o `cierre`.
  TextColumn get tipo => text()();

  /// Cuerpo del request sin `uuid_cliente` ni `secuencia` (JSON).
  TextColumn get payload => text()();

  /// Orden causal local (invariante 5): se envía siempre por esta secuencia,
  /// nunca por reloj de dispositivo.
  IntColumn get secuencia => integer()();

  TextColumn get estado => textEnum<EstadoRegistroEjecucion>().withDefault(
    Constant(EstadoRegistroEjecucion.pendiente.name),
  )();

  /// Se completa solo cuando el servidor rechaza el registro.
  TextColumn get motivoRechazo => text().nullable()();

  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
