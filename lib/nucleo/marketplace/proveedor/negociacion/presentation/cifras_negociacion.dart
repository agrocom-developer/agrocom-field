import 'package:decimal/decimal.dart';

import '../../../ui/formato_marketplace.dart';

/// Cifras de la negociación sin moneda ni unidad (la unidad la pone
/// `CifraCampo`): miles con punto, decimales con coma y sin ceros sobrantes.
/// Todo parte de [Decimal]; nunca pasa por `double`.
abstract final class CifrasNegociacion {
  static int _decimales(Decimal v, int maximo) =>
      v.toStringAsFixed(maximo).split('.').last.replaceAll('0', '').isEmpty
      ? 0
      : maximo;

  /// «62» o «62,5» (Bs por hectárea).
  static String bsHa(Decimal v) =>
      FormatoMarketplace.numero(v, decimales: _decimales(v, 2));

  /// «7.440» o «690,50» (monto en bolivianos).
  static String bs(Decimal v) =>
      FormatoMarketplace.numero(v, decimales: _decimales(v, 2));

  /// «120» u «85,5» (hectáreas).
  static String ha(Decimal v) =>
      FormatoMarketplace.numero(v, decimales: _decimales(v, 1));
}
