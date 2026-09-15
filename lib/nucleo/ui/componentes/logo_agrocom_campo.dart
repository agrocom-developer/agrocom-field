import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../imagenes_campo.dart';

/// El logo de Agrocom (isotipo + wordmark) tal como va sobre una foto o
/// sobre `fondoProfundo`. Es lo que nombra a la app en pantalla: ninguna
/// pantalla escribe "Agrocom" además de mostrarlo (ver `CLAUDE.md`,
/// convenciones).
///
/// [sombra] reproduce el `drop-shadow` del mockup con una copia del propio
/// PNG teñida de negro y desenfocada debajo — sigue la silueta real del
/// logo, cosa que un `BoxShadow` rectangular no haría. Se apaga donde el
/// fondo ya es liso y oscuro (no aporta nada ahí).
class LogoAgrocomCampo extends StatelessWidget {
  const LogoAgrocomCampo({this.ancho = 170, this.sombra = true, super.key});

  final double ancho;
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      ImagenesCampo.logo,
      width: ancho,
      fit: BoxFit.contain,
      semanticLabel: 'Agrocom',
    );
    if (!sombra) return logo;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 8),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x8C000000), // negro, alpha .55
                BlendMode.srcATop,
              ),
              child: Image.asset(
                ImagenesCampo.logo,
                width: ancho,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        logo,
      ],
    );
  }
}
