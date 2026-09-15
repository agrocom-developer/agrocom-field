import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Cuánto de la pantalla cubre la foto de [FondoFotoCampo].
enum CoberturaFondoFoto {
  /// Toda la pantalla, con un degradado que oscurece hacia abajo hasta
  /// `fondoProfundo` — onboarding, login.
  plena,

  /// Solo una franja superior de [FondoFotoCampo.altoSuperior] px que se
  /// funde con `fondoProfundo`; el resto es el fondo liso del `Scaffold` —
  /// inicio, detalle de orden.
  superior,
}

/// Foto decorativa de fondo + degradado a `fondoProfundo` + [child] encima.
/// Es la única forma de poner una foto detrás de una pantalla del modo campo:
/// el degradado garantiza el contraste del texto sobre cualquier foto (ADR
/// 0008 midió los tokens contra `fondoProfundo`, no contra una imagen), y
/// centraliza los stops en vez de que cada pantalla invente los suyos.
class FondoFotoCampo extends StatelessWidget {
  const FondoFotoCampo({
    required this.imagen,
    required this.child,
    this.cobertura = CoberturaFondoFoto.plena,
    this.altoSuperior = 300,
    this.alineacion = Alignment.center,
    super.key,
  });

  /// Ruta del asset (ver `ImagenesCampo`).
  final String imagen;
  final Widget child;
  final CoberturaFondoFoto cobertura;

  /// Alto de la franja cuando [cobertura] es [CoberturaFondoFoto.superior].
  final double altoSuperior;

  /// Qué parte de la foto queda a la vista al recortarla (`BoxFit.cover`).
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    final foto = Image.asset(
      imagen,
      fit: BoxFit.cover,
      alignment: alineacion,
      excludeFromSemantics: true,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        switch (cobertura) {
          CoberturaFondoFoto.plena => foto,
          CoberturaFondoFoto.superior => Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: altoSuperior,
            child: foto,
          ),
        },
        switch (cobertura) {
          CoberturaFondoFoto.plena => const DecoratedBox(
            decoration: BoxDecoration(gradient: _degradadoPleno),
          ),
          CoberturaFondoFoto.superior => Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: altoSuperior,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: _degradadoSuperior),
            ),
          ),
        },
        child,
      ],
    );
  }

  static const _degradadoPleno = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.38, 0.72, 1.0],
    colors: [
      Color(0x59_07110A), // fondoProfundo, alpha .35
      Color(0xB3_07110A), // alpha .7
      Color(0xF2_07110A), // alpha .95
      ColoresCampo.fondoProfundo,
    ],
  );

  static const _degradadoSuperior = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.62, 1.0],
    colors: [
      Color(0x59_07110A), // fondoProfundo, alpha .35
      Color(0xD1_07110A), // alpha .82
      ColoresCampo.fondoProfundo,
    ],
  );
}
