import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Track oscuro + fill lima, radio pill — p. ej. litros cargados sobre la
/// capacidad del tanque. [fraccion] se acota a `[0, 1]`.
class BarraProgresoCampo extends StatelessWidget {
  const BarraProgresoCampo({required this.fraccion, super.key});

  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final valor = fraccion.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: ColoresCampo.fondoProfundo.withValues(alpha: 0.5),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: valor,
          child: Container(color: ColoresCampo.acentoLima),
        ),
      ),
    );
  }
}
