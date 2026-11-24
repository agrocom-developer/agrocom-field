import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tema_campo.dart';

/// Pill con borde, transparente — acción secundaria junto a
/// `BotonPrimarioCampo` (p. ej. "Volver a medir" junto a "Guardar clima").
///
/// El alto es un mínimo, no un valor fijo: con el texto escalado al 200 %
/// el botón crece en vez de cortar la etiqueta.
class BotonSecundarioCampo extends StatelessWidget {
  const BotonSecundarioCampo({
    required this.texto,
    required this.onPressed,
    this.icono,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;

  /// Ícono opcional a la izquierda de la etiqueta; nunca reemplaza al texto.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final radio = Theme.of(context).extension<TemaCampo>()?.radioPill ?? 999;
    const etiqueta = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresCampo.textoPrincipal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(
            color: ColoresCampo.textoPrincipal.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
        ),
        child: icono == null
            ? Text(texto, textAlign: TextAlign.center, style: etiqueta)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: etiqueta,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
