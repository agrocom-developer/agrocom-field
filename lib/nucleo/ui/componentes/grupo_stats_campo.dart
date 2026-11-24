import 'package:flutter/material.dart';

import '../tokens_campo.dart';

/// Fila de `StatChipCampo` que no se rompe con texto grande: reparte el
/// ancho en partes iguales y, cuando el texto está escalado o el ancho no
/// alcanza, apila los datos uno debajo del otro (sistema visual, §3: ninguna
/// pantalla corta texto escalado al 200 %).
class GrupoStatsCampo extends StatelessWidget {
  const GrupoStatsCampo({required this.children, super.key});

  final List<Widget> children;

  /// Ancho mínimo de un dato para leerse en fila con el texto sin escalar.
  static const double _anchoMinimo = 88;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, restricciones) {
        final separaciones = EspaciadoCampo.s * (children.length - 1);
        final anchoPorDato =
            (restricciones.maxWidth - separaciones) / children.length;
        if (anchoPorDato < _anchoMinimo * escala) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: EspaciadoCampo.s),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: EspaciadoCampo.s),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
