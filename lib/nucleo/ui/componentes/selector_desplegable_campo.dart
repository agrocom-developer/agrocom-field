import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tema_campo.dart';
import '../tipografia_campo.dart';

/// Lista desplegable del modo campo, con la misma tarjeta translúcida y el
/// label mono en mayúscula de `CampoTextoCampo` — para elegir de una lista
/// que puede ser larga o venir de `drift` (motivo de cierre, auxiliar), donde
/// un `SelectorSegmentadoCampo` no entra. Envuelve un
/// `DropdownButtonFormField` real: la validación por `Form` y las pruebas
/// por `Key` siguen funcionando igual.
///
/// `null` en [valor] es «nada elegido todavía»; una opción con valor `null`
/// (p. ej. «Sin auxiliar») es válida si [T] es nulable.
class SelectorDesplegableCampo<T> extends StatelessWidget {
  const SelectorDesplegableCampo({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.onChanged,
    this.validator,
    super.key,
  });

  final String etiqueta;
  final List<(T valor, String etiqueta)> opciones;
  final T? valor;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaChica ?? 18;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 12, 4),
      decoration: BoxDecoration(
        color: ColoresCampo.textoPrincipal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiqueta.toUpperCase(), style: TipografiaCampo.etiquetaMono),
          DropdownButtonFormField<T>(
            initialValue: valor,
            isExpanded: true,
            dropdownColor: ColoresCampo.superficie,
            borderRadius: BorderRadius.circular(radio),
            iconEnabledColor: ColoresCampo.acentoLima,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: ColoresCampo.textoPrincipal,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 8, bottom: 6),
              errorStyle: TipografiaCampo.datoMonoDestacado.copyWith(
                fontSize: 11,
                color: ColoresCampo.acentoRojo,
              ),
            ),
            items: [
              for (final (valorOpcion, etiquetaOpcion) in opciones)
                DropdownMenuItem<T>(
                  value: valorOpcion,
                  child: Text(etiquetaOpcion),
                ),
            ],
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}
