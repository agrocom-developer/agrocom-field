import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// La estrella de calificación de las dos apps: siempre de oro
/// (`ColoresCampo.gradienteDorado`, distinto del ámbar de los botones), con
/// la misma forma redondeada. Llena, media o vacía (solo el contorno, en
/// oro). Decorativa: quien la usa lleva la semántica («Calificación 4 de 5»).
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
    final icono = Icon(
      media
          ? Icons.star_half_rounded
          : llena
          ? Icons.star_rounded
          : Icons.star_outline_rounded,
      size: tamano,
      color: color ?? Colors.white,
    );
    return ExcludeSemantics(
      child: color != null
          ? icono
          : ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ColoresCampo.gradienteDorado,
              ).createShader(r),
              child: icono,
            ),
    );
  }
}
