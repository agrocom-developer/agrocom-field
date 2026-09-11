import 'package:drift/drift.dart';

/// Espejo local de solo lectura de `GET /api/sync/catalogo`. Igual que
/// [OrdenCatalogo] (ver ese archivo para el detalle): PK = id de servidor,
/// nunca `uuid_cliente`, y sin FK saliente porque el pull es incremental por
/// cursor.
class PersonaCatalogo extends Table {
  IntColumn get id => integer()();

  TextColumn get nombre => text()();

  /// Valor libre tipo `"piloto"`/`"auxiliar"` — sin `textEnum` todavía porque
  /// no hay confirmado un conjunto cerrado de valores posibles.
  TextColumn get rol => text()();

  IntColumn get baseId => integer().nullable()();

  BoolColumn get activo => boolean()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
