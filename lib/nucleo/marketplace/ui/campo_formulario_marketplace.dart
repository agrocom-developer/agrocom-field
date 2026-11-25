import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Campo de formulario del marketplace: etiqueta visible arriba, borde de la
/// paleta activa y error en línea. A diferencia de `CampoTextoCampo` (modo
/// campo fijo), lee `PaletaCampo` y funciona en claro y oscuro.
///
/// Con [obscureText] agrega el control para ver u ocultar lo escrito.
/// [errorServidor] muestra un error que no viene del validador local (por
/// ejemplo un `422` por campo) sin pasar por `Form.validate`.
class CampoFormularioMarketplace extends StatefulWidget {
  const CampoFormularioMarketplace({
    required this.etiqueta,
    this.controller,
    this.validator,
    this.errorServidor,
    this.ayuda,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    super.key,
  });

  final String etiqueta;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final String? errorServidor;
  final String? ayuda;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// Radio del campo: el mismo del botón del tema (sistema visual, §4).
  static const double radio = 14;

  @override
  State<CampoFormularioMarketplace> createState() =>
      _CampoFormularioMarketplaceState();
}

class _CampoFormularioMarketplaceState
    extends State<CampoFormularioMarketplace> {
  late bool _oculto = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;

    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(CampoFormularioMarketplace.radio),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.etiqueta,
            style: texto.bodyMedium?.copyWith(
              color: paleta.texto,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Semantics(
          label: widget.etiqueta,
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            obscureText: _oculto,
            enableSuggestions: !widget.obscureText,
            autocorrect: false,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            cursorColor: paleta.acentoTexto,
            style: texto.bodyLarge?.copyWith(color: paleta.texto),
            decoration: InputDecoration(
              filled: true,
              fillColor: paleta.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.l,
              ),
              border: borde(paleta.bordeFuerte),
              enabledBorder: borde(paleta.bordeFuerte),
              disabledBorder: borde(paleta.borde),
              focusedBorder: borde(paleta.acentoTexto, 2),
              errorBorder: borde(paleta.error, 1.5),
              focusedErrorBorder: borde(paleta.error, 2),
              errorText: widget.errorServidor,
              errorMaxLines: 3,
              errorStyle: texto.bodyMedium?.copyWith(
                color: paleta.error,
                fontWeight: FontWeight.w600,
              ),
              helperText: widget.ayuda,
              helperMaxLines: 3,
              helperStyle: texto.bodyMedium?.copyWith(
                color: paleta.textoSecundario,
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      tooltip: _oculto
                          ? l10n.uiMostrarContrasena
                          : l10n.uiOcultarContrasena,
                      onPressed: () => setState(() => _oculto = !_oculto),
                      icon: Icon(
                        _oculto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: paleta.textoSecundario,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
