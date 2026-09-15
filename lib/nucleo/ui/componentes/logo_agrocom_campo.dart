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
///
/// El alto se fija desde la relación de aspecto del PNG, no se deja
/// calcular al cargar: así la pantalla reserva el espacio correcto desde el
/// primer frame (sin salto cuando decodifica) y, dentro de un
/// `IntrinsicHeight`, `RenderImage` no responde con el alto que tendría al
/// ancho total disponible — que es lo que hace cuando solo conoce `width`.
class LogoAgrocomCampo extends StatelessWidget {
  const LogoAgrocomCampo({this.ancho = 170, this.sombra = true, super.key});

  /// Alto/ancho del PNG (`agrocom_logo.png`, 574x407). Si el asset cambia
  /// de proporción, se actualiza acá.
  static const double relacionAlto = 407 / 574;

  final double ancho;
  final bool sombra;

  double get _alto => ancho * relacionAlto;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      ImagenesCampo.logo,
      width: ancho,
      height: _alto,
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
                height: _alto,
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
