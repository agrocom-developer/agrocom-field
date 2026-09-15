import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Botón circular con borde fino y un ícono — el "volver" de
/// `EncabezadoCampo`, la flecha "siguiente" del onboarding, el "cerrar" de
/// una vista superpuesta. [tamano] es el diámetro visible (40 por defecto,
/// 56 para una acción protagonista junto a un `BotonPrimarioCampo`); el
/// área táctil la extiende `IconButton` a 48 como mínimo (ADR 0003).
class BotonCircularCampo extends StatelessWidget {
  const BotonCircularCampo({
    required this.icono,
    required this.onPressed,
    this.tamano = 40,
    this.tooltip,
    super.key,
  });

  final IconData icono;
  final VoidCallback? onPressed;
  final double tamano;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.16),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icono,
          color: ColoresCampo.textoPrincipal,
          size: (tamano * 0.45).roundToDouble(),
        ),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
