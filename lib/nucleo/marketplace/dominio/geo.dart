import 'dart:math' as math;

/// Punto geográfico en grados decimales (WGS84). Las coordenadas no son
/// dinero ni hectáreas: `double` es el tipo correcto (invariante 9 de
/// `CLAUDE.md` solo alcanza a magnitudes de negocio).
class GeoPunto {
  const GeoPunto(this.latitud, this.longitud);

  final double latitud;
  final double longitud;

  @override
  bool operator ==(Object other) =>
      other is GeoPunto &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);

  @override
  String toString() => 'GeoPunto($latitud, $longitud)';
}

/// Centro aproximado (promedio de vértices) de un polígono.
GeoPunto centroDe(List<GeoPunto> poligono) {
  assert(poligono.isNotEmpty);
  final lat =
      poligono.map((p) => p.latitud).reduce((a, b) => a + b) / poligono.length;
  final lng =
      poligono.map((p) => p.longitud).reduce((a, b) => a + b) / poligono.length;
  return GeoPunto(lat, lng);
}

/// Distancia en kilómetros entre dos puntos (fórmula del haversine).
double distanciaKm(GeoPunto a, GeoPunto b) {
  const radioTierraKm = 6371.0;
  double rad(double g) => g * math.pi / 180;
  final dLat = rad(b.latitud - a.latitud);
  final dLng = rad(b.longitud - a.longitud);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitud)) *
          math.cos(rad(b.latitud)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * radioTierraKm * math.asin(math.sqrt(h));
}
