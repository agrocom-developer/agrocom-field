import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Oferta entrante de un servicio (proveedor): qué, dónde, cuánto y cuánto
/// tiempo queda para decidir. Es el momento más sensible del producto, por
/// eso la jerarquía es una sola: el pago y el tiempo arriba, aceptar abajo
/// con el botón más grande de la pantalla.
///
/// No lleva reloj propio: quien la muestra (un bloc) entrega [restante] y
/// [total]; así la cuenta regresiva es testeable y una sola fuente de
/// verdad. El monto llega ya formateado — nunca un `double` (invariante 9).
class OfertaServicioCampo extends StatelessWidget {
  const OfertaServicioCampo({
    required this.titulo,
    required this.detalle,
    required this.distancia,
    required this.monto,
    required this.restante,
    required this.total,
    required this.onAceptar,
    required this.onRechazar,
    super.key,
  });

  /// "Soja · 42 ha".
  final String titulo;

  /// "Lote 14, a 12 km de tu base".
  final String detalle;

  /// "12 km".
  final String distancia;

  /// Pago estimado ya formateado ("Bs 3.150").
  final String monto;

  final Duration restante;
  final Duration total;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  String get _restanteTexto {
    final seg = restante.inSeconds.clamp(0, 359999);
    final m = (seg ~/ 60).toString().padLeft(2, '0');
    final s = (seg % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final progreso = total.inMilliseconds == 0
        ? 0.0
        : (restante.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final porVencer = restante.inSeconds <= 10;
    final colorTiempo = porVencer ? paleta.error : paleta.acentoTexto;

    return Semantics(
      container: true,
      label:
          'Oferta de servicio: $titulo, $monto, quedan $_restanteTexto para responder',
      child: Container(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        decoration: BoxDecoration(
          color: ElevacionCampo.superficie(paleta, 2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: paleta.borde),
          boxShadow: ElevacionCampo.sombras(paleta, 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'NUEVO SERVICIO',
                    style: texto.labelSmall?.copyWith(
                      color: paleta.acentoTexto,
                    ),
                  ),
                ),
                _AnilloTiempo(
                  progreso: progreso,
                  color: colorTiempo,
                  pista: paleta.borde,
                  texto: _restanteTexto,
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text(titulo, style: texto.headlineMedium),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(detalle, style: texto.bodyMedium),
            const SizedBox(height: EspaciadoCampo.l),
            Row(
              children: [
                Expanded(
                  child: _Dato(etiqueta: 'PAGO', valor: monto, paleta: paleta),
                ),
                Expanded(
                  child: _Dato(
                    etiqueta: 'DISTANCIA',
                    valor: distancia,
                    paleta: paleta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            FilledButton(
              onPressed: () {
                HapticaCampo.confirmacion();
                onAceptar();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
              ),
              child: const Text('Aceptar servicio'),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            OutlinedButton(
              onPressed: onRechazar,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(ObjetivoTactilCampo.minimo),
              ),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.paleta,
  });

  final String etiqueta;
  final String valor;
  final PaletaCampo paleta;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: texto.labelSmall),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(valor, style: texto.headlineSmall),
      ],
    );
  }
}

class _AnilloTiempo extends StatelessWidget {
  const _AnilloTiempo({
    required this.progreso,
    required this.color,
    required this.pista,
    required this.texto,
  });

  final double progreso;
  final Color color;
  final Color pista;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _AnilloPainter(progreso: progreso, color: color, pista: pista),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  const _AnilloPainter({
    required this.progreso,
    required this.color,
    required this.pista,
  });

  final double progreso;
  final Color color;
  final Color pista;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final area = rect.deflate(3);
    canvas.drawArc(area, 0, 2 * math.pi, false, trazo..color = pista);
    canvas.drawArc(
      area,
      -math.pi / 2,
      2 * math.pi * progreso,
      false,
      trazo..color = color,
    );
  }

  @override
  bool shouldRepaint(_AnilloPainter anterior) =>
      anterior.progreso != progreso ||
      anterior.color != color ||
      anterior.pista != pista;
}
