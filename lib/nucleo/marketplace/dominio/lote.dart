import 'package:decimal/decimal.dart';

import 'geo.dart';

/// Terreno del cliente sobre el que se solicita un servicio.
class Lote {
  const Lote({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.cultivo,
    required this.hectareas,
    required this.poligono,
  });

  final String id;
  final String nombre;

  /// Municipio o zona agrícola, para mostrar («Cuatro Cañadas»).
  final String zona;
  final String cultivo;

  /// Superficie declarada, decimal exacto (ADR 0002).
  final Decimal hectareas;

  /// Vértices del contorno, en orden.
  final List<GeoPunto> poligono;

  GeoPunto get centro => centroDe(poligono);
}
