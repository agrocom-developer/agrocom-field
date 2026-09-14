import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tema_campo.dart';

/// Pill con borde, transparente — acción secundaria junto a
/// `BotonPrimarioCampo` (p. ej. "Volver a medir" junto a "Guardar clima").
class BotonSecundarioCampo extends StatelessWidget {
  const BotonSecundarioCampo({
    required this.texto,
    required this.onPressed,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radio = Theme.of(context).extension<TemaCampo>()?.radioPill ?? 999;
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresCampo.textoPrincipal,
          side: BorderSide(
            color: ColoresCampo.textoPrincipal.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
