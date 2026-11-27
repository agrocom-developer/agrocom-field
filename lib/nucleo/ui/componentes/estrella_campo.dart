import 'package:flutter/material.dart';

import '../paleta_campo.dart';

/// La estrella de calificación de las dos apps: siempre dorada
/// (`paleta.ambar`), con la misma forma redondeada. Llena, media o vacía
/// (solo el contorno, en el mismo dorado). Decorativa: quien la usa lleva la
/// semántica («Calificación 4 de 5»).
///
/// [color] solo existe para los renglones pequeños de apoyo (barras de
/// puntaje) donde la estrella va tenue; no se usa para calificar.
class EstrellaCampo extends StatelessWidget {
  const EstrellaCampo({
    this.tamano = 20,
    this.llena = true,
    this.media = false,
    this.color,
    super.key,
  });

  final double tamano;
  final bool llena;

  /// Media estrella; tiene prioridad sobre [llena].
  final bool media;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        media
            ? Icons.star_half_rounded
            : llena
            ? Icons.star_rounded
            : Icons.star_outline_rounded,
        size: tamano,
        color: color ?? context.paleta.ambar,
      ),
    );
  }
}
