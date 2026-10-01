import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de solo lectura de `GET /api/sync/catalogo`. Igual que
/// [OrdenCatalogo] (ver ese archivo para el detalle): PK = id de servidor,
/// nunca `uuid_cliente`, y sin FK saliente porque el pull es incremental por
/// cursor.
class LoteCatalogo extends Table {
  IntColumn get id => integer()();

  IntColumn get propiedadId => integer()();

  TextColumn get codigo => text()();

  /// Hectáreas: nunca `double` (invariante 9 de CLAUDE.md).
  TextColumn get hectareas => text().map(const DecimalDriftConverter())();

  /// GeoJSON u objeto arbitrario, o `null`. Texto plano a propósito: el
  /// repositorio de catálogo hace `jsonEncode`/`jsonDecode` a mano al leer y
  /// escribir; esta columna no estructura el contenido.
  TextColumn get geometria => text().nullable()();

  TextColumn get restricciones => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
