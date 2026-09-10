import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

/// Dinero y hectáreas viajan como string decimal en el contrato de API
/// (invariante 9 de CLAUDE.md; ver docs/decisiones/0002 de este repo).
class DecimalJsonConverter implements JsonConverter<Decimal, String> {
  const DecimalJsonConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  @override
  String toJson(Decimal object) => object.toString();
}
