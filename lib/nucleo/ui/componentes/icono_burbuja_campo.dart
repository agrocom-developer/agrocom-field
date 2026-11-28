import 'package:flutter/material.dart';

import '../paleta_campo.dart';

/// Ícono de Material dentro de un círculo ámbar: el acento del 10 % que
/// marca cada fila o beneficio. Decorativo: la fila que lo contiene lleva el
/// texto y la semántica.
class IconoBurbujaCampo extends StatelessWidget {
  const IconoBurbujaCampo(this.icono, {this.tamano = 44, super.key});

  final IconData icono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ExcludeSemantics(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(color: paleta.ambar, shape: BoxShape.circle),
        child: Icon(icono, size: tamano * 0.5, color: paleta.sobreAmbar),
      ),
    );
  }
}
