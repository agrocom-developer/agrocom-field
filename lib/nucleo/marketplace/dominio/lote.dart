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

/// Hectáreas de un contorno dibujado, como decimal exacto con un decimal.
///
/// La geometría se calcula en `double` (las coordenadas lo son) y se
/// convierte a [Decimal] en este único punto: a partir de acá la superficie
/// es una magnitud de negocio y nunca vuelve a `double` (ADR 0002).
Decimal hectareasDePoligono(List<GeoPunto> poligono) =>
    Decimal.parse((areaMetrosCuadrados(poligono) / 10000).toStringAsFixed(1));
