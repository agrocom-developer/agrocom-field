import 'package:drift/drift.dart';

/// `pendiente → subido | rechazado`. Vocabulario propio de la cola de fotos
/// de ejecución, como el de `evidencia_local`.
enum EstadoFotoEjecucion { pendiente, subido, rechazado }

/// Cola de fotos de avance de un servicio adjudicado (ADR 0016), SEPARADA de
/// `registro_ejecucion` (invariante 7 de CLAUDE.md): el contrato de subida es
/// multipart, una foto por request, y el archivo vive en el filesystem.
///
/// El archivo ya está comprimido a menos de 300 KB cuando se inserta la fila.
/// El servidor exige las fotos mínimas antes de finalizar; el cierre pendiente
/// se completa al subir la que falta, en el orden en que lleguen.
class FotoEjecucion extends Table {
  TextColumn get uuidCliente => text()();

  IntColumn get solicitudId => integer()();

  /// `foto_avance` o `foto_final`.
  TextColumn get tipo => text()();

  /// `uuid_cliente` del registro de avance al que pertenece la foto, si lo
  /// hay.
  TextColumn get avanceUuidCliente => text().nullable()();

  TextColumn get rutaArchivoLocal => text()();

  TextColumn get hashSha256 => text()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get estado => textEnum<EstadoFotoEjecucion>().withDefault(
    Constant(EstadoFotoEjecucion.pendiente.name),
  )();

  TextColumn get motivoRechazo => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
