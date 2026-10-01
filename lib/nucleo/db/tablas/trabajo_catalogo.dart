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

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
