import 'package:decimal/decimal.dart';

import '../../../dominio/geo.dart';

/// Distancia en línea recta del piloto al lote, calculada en el dispositivo
/// con el haversine. La posición del piloto no sale del teléfono: este
/// cálculo recibe los dos puntos, devuelve kilómetros y no guarda nada.
abstract final class DistanciaAlLote {
  /// Kilómetros con un decimal («12,4 km»), en decimal exacto.
  static Decimal kilometros(GeoPunto piloto, GeoPunto lote) =>
      Decimal.parse(distanciaKm(piloto, lote).toStringAsFixed(1));
}
