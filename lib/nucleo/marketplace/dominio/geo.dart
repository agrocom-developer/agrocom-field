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

/// Punto en polígono (trazado de rayos).
bool poligonoContiene(List<GeoPunto> poligono, GeoPunto p) {
  var dentro = false;
  for (var i = 0, j = poligono.length - 1; i < poligono.length; j = i++) {
    final a = poligono[i];
    final b = poligono[j];
    final cruza =
        (a.latitud > p.latitud) != (b.latitud > p.latitud) &&
        p.longitud <
            (b.longitud - a.longitud) *
                    (p.latitud - a.latitud) /
                    (b.latitud - a.latitud) +
                a.longitud;
    if (cruza) dentro = !dentro;
  }
  return dentro;
}

/// Área en metros cuadrados de un polígono geográfico. Proyecta los vértices
/// a un plano local alrededor del centro (suficiente para un lote: el error
/// es menor al 0,1 % en parcelas de pocos kilómetros) y aplica la fórmula del
/// área de Gauss. Con menos de tres vértices el área es cero.
double areaMetrosCuadrados(List<GeoPunto> poligono) {
  if (poligono.length < 3) return 0;
  const radioTierraM = 6371008.8;
  final centro = centroDe(poligono);
  double rad(double g) => g * math.pi / 180;
  final escalaX = radioTierraM * math.cos(rad(centro.latitud));
  final xs = [
    for (final p in poligono) rad(p.longitud - centro.longitud) * escalaX,
  ];
  final ys = [
    for (final p in poligono) rad(p.latitud - centro.latitud) * radioTierraM,
  ];
  var suma = 0.0;
  for (var i = 0; i < poligono.length; i++) {
    final j = (i + 1) % poligono.length;
    suma += xs[i] * ys[j] - xs[j] * ys[i];
  }
  return suma.abs() / 2;
}
