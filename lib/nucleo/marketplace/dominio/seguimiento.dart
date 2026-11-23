import 'package:decimal/decimal.dart';

import 'geo.dart';
import 'servicio.dart';

/// Fotograma del seguimiento en vivo: dónde va el dron y cuánto avanzó.
class SeguimientoVivo {
  const SeguimientoVivo({
    required this.estado,
    required this.posicionDron,
    required this.hectareasCubiertas,
    required this.hectareasDeclaradas,
    required this.trazado,
    this.etaMinutos,
  });

  final EstadoServicio estado;
  final GeoPunto posicionDron;
  final Decimal hectareasCubiertas;
  final Decimal hectareasDeclaradas;

  /// Recorrido ya hecho, para dibujar la estela.
  final List<GeoPunto> trazado;
  final int? etaMinutos;

  double get progreso {
    if (hectareasDeclaradas == Decimal.zero) return 0;
    final r = (hectareasCubiertas / hectareasDeclaradas).toDecimal(
      scaleOnInfinitePrecision: 4,
    );
    return r.toDouble().clamp(0.0, 1.0);
  }
}
