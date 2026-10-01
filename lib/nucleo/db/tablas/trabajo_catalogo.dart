import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de solo lectura de `trabajos[]` de `GET /api/sync/catalogo`
/// (`TrabajoCatalogo` en el `openapi.yaml` de `agrocom-api`, HU-70): el
/// trabajo que el jefe de campo asignó desde el panel a un equipo al
/// repartir una orden vigente. Mismo criterio que [OrdenCatalogo]: PK = id
/// de servidor y sin FK saliente, porque el pull es incremental por cursor.
///
/// Distinta de `TrabajoLocal` a propósito (invariante 4 de CLAUDE.md, un
/// solo rol escritor por tipo de registro): esta fila la escribe el panel y
/// el dispositivo solo la espeja; `TrabajoLocal` es lo que el piloto
/// escribe y encola. Nunca se mezclan en una misma tabla.
class TrabajoCatalogo extends Table {
  IntColumn get id => integer()();

  /// El `uuid_cliente` que generó el panel al confirmar la asignación — la
  /// app lo usa TAL CUAL para abrir sesiones sobre este trabajo, nunca
  /// genera uno propio (invariante 2 aplicada a un registro de origen
  /// servidor). Único: dos filas con el mismo `uuid_cliente` serían el
  /// mismo trabajo.
  TextColumn get uuidCliente => text().unique()();

  IntColumn get ordenId => integer()();

  /// Un trabajo es de UN lote, a diferencia de la orden (`lotes[]`).
  IntColumn get loteId => integer()();

  /// Hectáreas que el jefe de campo le asignó a ESTE equipo — no la
  /// superficie del lote ni la de la orden. Nunca `double` (invariante 9 de
  /// CLAUDE.md).
  TextColumn get hectareasDeclaradas =>
      text().map(const DecimalDriftConverter())();

  IntColumn get equipoTrabajoId => integer()();

  // Límites climáticos y parámetros de vuelo (v12, tarea 23): el servidor
  // los movió de `ordenes[]` a `trabajos[]`. En `agrocom-api` son de la
  // tanda (`OrdenTrabajo`) que contiene este trabajo y, desde #309, viajan
  // EFECTIVOS: viento, temperatura y humedad máxima siempre con valor (el
  // propio o el default del sistema); humedad mínima, altura, velocidad y
  // ancho de pasada en `null` si la Orden de Trabajo no los fija. Nullable
  // los siete igual: por la migración v11→v12 (`ALTER TABLE`, conserva las
  // filas) y porque una fila bajada antes de #309 puede tenerlos en `null`
  // hasta el pull completo que fuerza el reset de cursor de v13. Nunca
  // `double` (invariante 9 de CLAUDE.md).

  TextColumn get humedadMinPct => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get vientoMaxKmh => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get temperaturaMaxC => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get humedadMaxPct => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get alturaVueloM => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get velocidadVueloKmh => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get anchoPasadaM => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  DateTimeColumn get updatedAt => dateTime()();

  // Retiro (v14, tarea 26, `agrocom-api` #313): la fila se MARCA, nunca se
  // borra — es espejo del servidor y puede volver (una orden `pausada` que
  // pasa a `vigente` llega otra vez en `ordenes[]` y se desmarca).
  // `motivoRetiro` en `null` = no retirada. Nullable las tres por la
  // migración (`ALTER TABLE`, conserva las filas).

  /// Para un trabajo: el `motivo` de `trabajos_retirados` (`dado_de_baja`,
  /// `reasignado`, `cerrado`, `orden_cerrada`), o el motivo local `fuera_de_alcance` cuando el barrido completo
  /// (pull desde cursor vacío) terminó sin traerla — ver
  /// `CatalogoRepository`.
  TextColumn get motivoRetiro => text().nullable()();

  /// `updated_at` del servidor en la sección de retirados. `null` en el
  /// retiro local por barrido: ese no tiene momento del servidor.
  DateTimeColumn get retiroActualizadoEn => dateTime().nullable()();

  /// Si llegó en el barrido completo en curso. Solo tiene sentido mientras
  /// `CursorCatalogo.barridoEnCurso` es verdadero: al empezar el barrido se
  /// pone en `false` en todas las filas y cada upsert lo deja en `true`.
  BoolColumn get vistoEnBarrido => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
