import 'package:decimal/decimal.dart';

import 'foto_terreno.dart';
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
    this.fotos = const [],
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

  /// Fotos del estado del terreno (hasta 8), con URL firmada de corta vida.
  final List<FotoTerreno> fotos;

  GeoPunto get centro => centroDe(poligono);
}

/// Hectáreas de un contorno dibujado, como decimal exacto con un decimal.
///
/// La geometría se calcula en `double` (las coordenadas lo son) y se
/// convierte a [Decimal] en este único punto: a partir de acá la superficie
/// es una magnitud de negocio y nunca vuelve a `double` (ADR 0002).
Decimal hectareasDePoligono(List<GeoPunto> poligono) =>
    Decimal.parse((areaMetrosCuadrados(poligono) / 10000).toStringAsFixed(1));
