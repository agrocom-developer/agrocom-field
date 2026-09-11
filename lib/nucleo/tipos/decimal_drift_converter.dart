import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

/// Equivalente `drift` de [DecimalJsonConverter] (ver
/// `decimal_json_converter.dart` y ADR 0002 de este repo): dinero y
/// hectáreas nunca en `double`/`float` (invariante 9 de CLAUDE.md), tampoco
/// una vez que el valor ya vive en una columna SQLite local.
///
/// Para una columna no nullable: `text().map(const DecimalDriftConverter())()`.
/// Para una columna nullable, envolver con `NullAwareTypeConverter.wrap(...)`
/// antes de pasarlo a `.map()` — drift exige que el tipo Dart del converter
/// (`Decimal?`) sea nullable si la columna lo es.
class DecimalDriftConverter extends TypeConverter<Decimal, String> {
  const DecimalDriftConverter();

  @override
  Decimal fromSql(String fromDb) => Decimal.parse(fromDb);

  @override
  String toSql(Decimal value) => value.toString();
}
