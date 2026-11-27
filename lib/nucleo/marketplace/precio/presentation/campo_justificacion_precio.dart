import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../justificacion_precio.dart';

/// Campo opcional «Justificación del precio»: hasta 500 caracteres, con
/// contador, sin saltos de línea. Cada parte escribe el suyo y la contraparte
/// lo lee junto a la oferta.
class CampoJustificacionPrecio extends StatelessWidget {
  const CampoJustificacionPrecio({
    required this.controller,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, valor, _) {
        final usados = valor.text.length;
        return TextField(
          key: const ValueKey('campo-justificacion-precio'),
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          minLines: 2,
          maxLines: 4,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
            LengthLimitingTextInputFormatter(JustificacionPrecio.maximo),
          ],
          decoration: InputDecoration(
            labelText: l10n.precioJustificacionEtiqueta,
            helperText: l10n.precioJustificacionAyuda,
            helperMaxLines: 2,
            alignLabelWithHint: true,
            counter: Padding(
              padding: const EdgeInsets.only(top: EspaciadoCampo.xs),
              child: Semantics(
                label: l10n.precioJustificacionContador(
                  usados,
                  JustificacionPrecio.maximo,
                ),
                excludeSemantics: true,
                child: Text(
                  l10n.precioJustificacionContador(
                    usados,
                    JustificacionPrecio.maximo,
                  ),
                  style: texto.bodySmall?.copyWith(
                    color: usados >= JustificacionPrecio.maximo
                        ? paleta.error
                        : paleta.textoSecundario,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
