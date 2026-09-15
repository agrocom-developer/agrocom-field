import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tema_campo.dart';
import '../tipografia_campo.dart';

/// Campo de texto del modo campo: tarjeta translúcida con el label mono en
/// mayúscula arriba y el valor grande abajo, borde lima mientras tiene el
/// foco. Reemplaza al `TextFormField` "filled" de ADR 0003 en las pantallas
/// que adoptan este modo — envuelve un `TextFormField` real, así la
/// validación por `Form` y las pruebas por `Key` siguen funcionando igual.
///
/// [accionTexto]/[onAccion] es una acción corta a la derecha del valor
/// ("VER"/"OCULTAR" en una contraseña), en mono lima; sin ella, el campo
/// ocupa todo el ancho.
class CampoTextoCampo extends StatefulWidget {
  const CampoTextoCampo({
    required this.etiqueta,
    this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.autocorrect = true,
    this.validator,
    this.onFieldSubmitted,
    this.accionTexto,
    this.onAccion,
    super.key,
  });

  final String etiqueta;
  final TextEditingController? controller;
  final bool enabled;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final String? accionTexto;
  final VoidCallback? onAccion;

  @override
  State<CampoTextoCampo> createState() => _CampoTextoCampoState();
}

class _CampoTextoCampoState extends State<CampoTextoCampo> {
  final _focusNode = FocusNode();
  bool _enfocado = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_alCambiarFoco);
  }

  void _alCambiarFoco() {
    if (_enfocado != _focusNode.hasFocus) {
      setState(() => _enfocado = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_alCambiarFoco)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaChica ?? 18;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(18, 13, 12, 10),
      decoration: BoxDecoration(
        color: ColoresCampo.textoPrincipal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(
          color: _enfocado
              ? ColoresCampo.acentoLima.withValues(alpha: 0.45)
              : ColoresCampo.textoPrincipal.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.etiqueta.toUpperCase(),
                  style: TipografiaCampo.etiquetaMono,
                ),
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  enableSuggestions: !widget.obscureText,
                  autocorrect: widget.autocorrect && !widget.obscureText,
                  textInputAction: widget.textInputAction,
                  keyboardType: widget.keyboardType,
                  cursorColor: ColoresCampo.acentoLima,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: ColoresCampo.textoPrincipal,
                    // Los puntos de una contraseña, en mono y espaciados,
                    // como el mockup — el texto humano sigue en la fuente
                    // de plataforma.
                    fontFamily: widget.obscureText ? 'monospace' : null,
                    letterSpacing: widget.obscureText ? 4 : null,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 8, bottom: 2),
                    errorStyle: TipografiaCampo.datoMonoDestacado.copyWith(
                      fontSize: 11,
                      color: ColoresCampo.acentoRojo,
                    ),
                  ),
                  validator: widget.validator,
                  onFieldSubmitted: widget.onFieldSubmitted,
                ),
              ],
            ),
          ),
          if (widget.accionTexto != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: widget.onAccion,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: ColoresCampo.acentoLima,
                textStyle: TipografiaCampo.datoMonoDestacado,
              ),
              child: Text(widget.accionTexto!.toUpperCase()),
            ),
          ],
        ],
      ),
    );
  }
}
