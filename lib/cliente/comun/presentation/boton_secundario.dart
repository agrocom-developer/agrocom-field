import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Acción secundaria en texto, junto a un `BotonPrincipal` o dentro de un
/// aviso. Usa el acento legible sobre el fondo (en claro, el lima de marca
/// no alcanza el contraste AA como color de texto).
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    required this.texto,
    required this.onPressed,
    this.icono,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final estilo = TextButton.styleFrom(
      foregroundColor: context.paleta.acentoTexto,
      minimumSize: const Size(64, ObjetivoTactilCampo.minimo),
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    final etiqueta = Text(texto, textAlign: TextAlign.center);
    return icono == null
        ? TextButton(onPressed: onPressed, style: estilo, child: etiqueta)
        : TextButton.icon(
            onPressed: onPressed,
            style: estilo,
            icon: Icon(icono),
            label: etiqueta,
          );
  }
}
