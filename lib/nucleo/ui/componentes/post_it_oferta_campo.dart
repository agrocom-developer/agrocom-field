import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'cifra_campo.dart';

/// Oferta de un piloto como post-it: papel amarillo en degradado, esquina
/// doblada, giro de 1° (sin giro con movimiento reducido) y la insignia
/// «ELEGIDO» cuando es la oferta que el cliente eligió. Se dibuja en código,
/// nunca como imagen.
class PostItOfertaCampo extends StatelessWidget {
  const PostItOfertaCampo({
    required this.piloto,
    required this.precioPorHectarea,
    required this.total,
    this.detalle,
    this.elegido = false,
    this.onTap,
    super.key,
  });

  final String piloto;

  /// Precio por hectárea con formato, sin unidad.
  final String precioPorHectarea;

  /// Total con formato, sin moneda.
  final String total;

  /// Apoyo bajo el nombre ("4,9 de 5 · 12 km").
  final String? detalle;

  final bool elegido;
  final VoidCallback? onTap;

  static const double _doblez = 28;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final giro = MovimientoCampo.reducido(context) ? 0.0 : math.pi / 180;
    return Semantics(
      container: true,
      button: onTap != null,
      selected: elegido,
      label:
          'Oferta de $piloto: $precioPorHectarea bolivianos por hectárea, '
          'total $total bolivianos${elegido ? ', elegida' : ''}',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: giro,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: const _RecorteDoblez(_doblez),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [paleta.papel, paleta.papel2],
                    ),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(EspaciadoCampo.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            piloto,
                            style: TipografiaCampo.tituloSeccion.copyWith(
                              color: paleta.sobrePapel,
                            ),
                          ),
                          if (detalle != null)
                            Text(
                              detalle!,
                              style: TipografiaCampo.datoMono.copyWith(
                                color: paleta.sobrePapel,
                              ),
                            ),
                          const SizedBox(height: EspaciadoCampo.m),
                          CifraCampo(
                            valor: precioPorHectarea,
                            unidad: 'Bs/ha',
                            color: paleta.sobrePapel,
                          ),
                          const SizedBox(height: EspaciadoCampo.xs),
                          CifraCampo(
                            valor: total,
                            unidad: 'Bs',
                            estilo: TipografiaCampo.cifraMedia,
                            color: paleta.sobrePapel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size.square(_doblez),
                  painter: _PintorDoblez(paleta.papelDoblez),
                ),
              ),
            ),
            if (elegido)
              Positioned(
                top: -EspaciadoCampo.s,
                right: EspaciadoCampo.m,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: paleta.grafito,
                    borderRadius: BorderRadius.circular(RadioCampo.chip),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspaciadoCampo.m,
                      vertical: EspaciadoCampo.xs,
                    ),
                    child: Text(
                      'ELEGIDO',
                      style: TipografiaCampo.etiquetaMono.copyWith(
                        color: paleta.sobreGrafito,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Corta la esquina inferior derecha en diagonal.
class _RecorteDoblez extends CustomClipper<Path> {
  const _RecorteDoblez(this.lado);

  final double lado;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - lado)
    ..lineTo(size.width - lado, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_RecorteDoblez viejo) => viejo.lado != lado;
}

class _PintorDoblez extends CustomPainter {
  const _PintorDoblez(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final trozo = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(trozo, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorDoblez viejo) => viejo.color != color;
}
