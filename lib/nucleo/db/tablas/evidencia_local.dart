import 'package:drift/drift.dart';

/// Vocabulario LOCAL de esta cola — NO es el `EstadoSync` de `ColaSync`.
/// `pendiente → subido | rechazado`, sin el paso intermedio `enviado` de
/// `ColaSync`: acá un solo `POST /api/evidencias` por fila resuelve el
/// resultado en la misma llamada, no hay una confirmación de lote separada
/// del envío (ver `EvidenciaSyncEngine`).
enum EstadoEvidenciaLocal { pendiente, subido, rechazado }

/// Cola de evidencias (TE-07) — SEPARADA de `ColaSync` por diseño
/// (invariante 8 de CLAUDE.md: "una cola de sincronización separada de los
/// registros livianos"), no una tabla compartida con un discriminador: el
/// contrato de subida es distinto (`POST /api/evidencias`, multipart, un
/// POST por evidencia, nunca un lote) y el archivo real vive en el
/// filesystem, no en esta tabla.
class EvidenciaLocal extends Table {
  /// Identidad generada en el dispositivo antes de tocar la red (invariante
  /// 2 de CLAUDE.md), nunca en el servidor ni reutilizada entre reintentos.
  /// Es la PK de la tabla (ver [primaryKey] más abajo).
  TextColumn get uuidCliente => text()();

  /// Catálogo cerrado del servidor (`captura_rc`, `imagen_campo`,
  /// `foto_incidencia`, `comprobante`, `firma_acta` — ver
  /// `docs/api/openapi.yaml` de `agrocom-api`, path `/api/evidencias`). Sin
  /// `textEnum` a propósito, mismo criterio que `SesionLocal.motivoCierre`:
  /// ese catálogo lo valida y es dueño el servidor, no este dispositivo.
  TextColumn get tipo => text()();

  /// Dónde quedó el archivo YA COMPRIMIDO en el filesystem local — nunca el
  /// binario en una columna `drift` (esta tabla solo referencia la ruta).
  TextColumn get rutaArchivoLocal => text()();

  /// SHA-256 sobre los bytes ya comprimidos, calculado en el dispositivo
  /// (ADR 0009 de `agrocom-api`) — se manda como `hash_dispositivo` en el
  /// POST; el servidor lo recalcula igual y rechaza si no coincide.
  TextColumn get hashSha256 => text()();

  /// Momento de captura, mandado como `fecha` (ISO 8601) en el POST.
  DateTimeColumn get fecha => dateTime()();

  /// `pendiente → subido | rechazado`. Vocabulario LOCAL de esta cola, no
  /// confundir con `EstadoSync` de `ColaSync` (invariante 8: son colas
  /// separadas).
  TextColumn get estado => textEnum<EstadoEvidenciaLocal>().withDefault(
    Constant(EstadoEvidenciaLocal.pendiente.name),
  )();

  /// Se completa solo cuando el servidor responde `rechazado {motivo}`.
  TextColumn get motivoRechazo => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
