import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Ciclo de una onda del radar. Lento a propósito: acompaña una espera, no
/// pide atención.
const _ciclo = Duration(milliseconds: 2600);

/// Animación de la búsqueda de proveedor: ondas que salen del lote y
/// alcanzan a los proveedores cercanos. Con [amplio] las ondas llegan más
/// lejos y aparecen más proveedores (la ronda de terceros).
///
/// Es una de las pocas animaciones en bucle del producto (sistema visual,
/// §7): representa una espera activa del servidor. Con movimiento reducido
/// queda quieta, con las ondas dibujadas.
class RadarBusqueda extends StatefulWidget {
  const RadarBusqueda({required this.amplio, this.tamano = 220, super.key});

  final bool amplio;
  final double tamano;

  @override
  State<RadarBusqueda> createState() => _RadarBusquedaState();
}

class _RadarBusquedaState extends State<RadarBusqueda>
    with SingleTickerProviderStateMixin {
  late final AnimationController _onda = AnimationController(
    vsync: this,
    duration: _ciclo,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MovimientoCampo.reducido(context)) {
      _onda
        ..stop()
        ..value = 0.5;
    } else if (!_onda.isAnimating) {
      _onda.repeat();
    }
  }

  @override
  void dispose() {
    _onda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.tamano,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PintorRadar(
                    avance: _onda,
                    color: paleta.acentoTexto,
                    colorPunto: paleta.textoSecundario,
                    amplio: widget.amplio,
                  ),
                ),
              ),
            ),
            Container(
              width: widget.tamano * 0.3,
              height: widget.tamano * 0.3,
              decoration: BoxDecoration(
                color: paleta.acento,
                shape: BoxShape.circle,
                boxShadow: ElevacionCampo.sombras(paleta, 2),
              ),
              child: Icon(
                Icons.flight_rounded,
                color: paleta.sobreAcento,
                size: widget.tamano * 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PintorRadar extends CustomPainter {
  _PintorRadar({
    required this.avance,
    required this.color,
    required this.colorPunto,
    required this.amplio,
  }) : super(repaint: avance);

  final Animation<double> avance;
  final Color color;
  final Color colorPunto;
  final bool amplio;

  /// Proveedores alrededor del lote: ángulo en vueltas y distancia relativa
  /// al radio. Los primeros son los cercanos (propios); el resto aparece al
  /// ampliar la búsqueda a terceros.
  static const _proveedores = [
    (0.08, 0.50),
    (0.57, 0.44),
    (0.33, 0.82),
    (0.78, 0.88),
    (0.93, 0.70),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2;
    final nucleo = radio * 0.3;
    final alcance = amplio ? radio : radio * 0.68;
    final t = avance.value;

    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const ondas = 3;
    for (var i = 0; i < ondas; i++) {
      final fase = (t + i / ondas) % 1.0;
      trazo.color = color.withValues(alpha: 0.55 * (1 - fase));
      canvas.drawCircle(centro, nucleo + (alcance - nucleo) * fase, trazo);
    }

    final cuantos = amplio ? _proveedores.length : 2;
    final relleno = Paint();
    for (var i = 0; i < cuantos; i++) {
      final (vuelta, distancia) = _proveedores[i];
      final angulo = vuelta * 2 * math.pi;
      final posicion =
          centro +
          Offset(math.cos(angulo), math.sin(angulo)) * (radio * distancia);
      // El punto se enciende cuando lo alcanza una onda.
      final r = nucleo + (alcance - nucleo) * t;
      final cerca = (1 - ((radio * distancia - r).abs() / (radio * 0.25)))
          .clamp(0.0, 1.0);
      relleno.color = Color.lerp(
        colorPunto,
        color,
        cerca,
      )!.withValues(alpha: 0.45 + 0.55 * cerca);
      canvas.drawCircle(posicion, 5 + 2 * cerca, relleno);
    }
  }

  @override
  bool shouldRepaint(_PintorRadar anterior) =>
      anterior.color != color ||
      anterior.colorPunto != colorPunto ||
      anterior.amplio != amplio;
}
