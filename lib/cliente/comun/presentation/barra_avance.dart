import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Barra de avance de 0 a 1 que se desliza hasta el valor nuevo en lugar de
/// saltar. Con «reducir movimiento» salta.
class BarraAvance extends StatelessWidget {
  const BarraAvance({
    required this.valor,
    required this.etiqueta,
    this.alto = EspaciadoCampo.s,
    super.key,
  });

  /// De 0 a 1.
  final double valor;

  /// Lo que anuncia el lector de pantalla («46,8 ha de 120 ha»).
  final String etiqueta;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final objetivo = valor.clamp(0.0, 1.0);
    return Semantics(
      label: 'Avance: $etiqueta',
      value: '${(objetivo * 100).round()} %',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(alto),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: objetivo),
            duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
            curve: MovimientoCampo.movimiento,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: alto,
              backgroundColor: paleta.borde,
              color: paleta.acentoTexto,
            ),
          ),
        ),
      ),
    );
  }
}
