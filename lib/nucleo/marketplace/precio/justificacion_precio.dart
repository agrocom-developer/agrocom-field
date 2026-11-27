import 'package:decimal/decimal.dart';

/// Reglas de la justificación del precio: el texto opcional con que cada
/// parte explica el precio por hectárea que propone. Lo escribe solo su autor,
/// en su propia fila, y la contraparte lo ve.
abstract final class JustificacionPrecio {
  /// Máximo de caracteres que acepta el servidor.
  static const maximo = 500;

  /// Deja el texto listo para enviar: sin saltos de línea ni espacios
  /// repetidos, recortado a [maximo]. Un texto vacío es `null` (no se envía).
  static String? normalizar(String? texto) {
    if (texto == null) return null;
    final limpio = texto.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (limpio.isEmpty) return null;
    return limpio.length <= maximo ? limpio : limpio.substring(0, maximo);
  }
}

/// El total estimado que se muestra de solo lectura junto al precio por
/// hectárea: hectáreas por precio, en decimal exacto. Nunca se envía: el
/// servidor lo calcula (`monto_estimado`) y lo devuelve.
Decimal? totalEstimado(Decimal? hectareas, Decimal? precioHa) {
  if (hectareas == null || precioHa == null) return null;
  return hectareas * precioHa;
}
