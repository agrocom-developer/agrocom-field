import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tipografia_campo.dart';

/// Fila «etiqueta … valor» en mono, dentro de una `TarjetaCampo` — el
/// patrón de la tarjeta «Parámetros de vuelo acordados» de la vista previa
/// 08, que cada pantalla con datos técnicos repetía a mano. Reemplaza las
/// filas «Etiqueta: valor» del Material estándar de ADR 0003.
///
/// La semántica lee «etiqueta: valor» como una sola frase, igual que el
/// texto que reemplaza.
class FilaDatoCampo extends StatelessWidget {
  const FilaDatoCampo({
    required this.etiqueta,
    required this.valor,
    this.unidad,
    super.key,
  });

  final String etiqueta;
  final String valor;

  /// Se agrega al valor separada por un espacio (p. ej. «3 m»); `null` si el
  /// valor no lleva unidad o no hay dato.
  final String? unidad;

  @override
  Widget build(BuildContext context) {
    final estilo = TipografiaCampo.datoMono.copyWith(
      fontSize: 13,
      color: ColoresCampo.textoPrincipal.withValues(
        alpha: OpacidadesCampo.media,
      ),
    );
    final textoValor = unidad == null ? valor : '$valor $unidad';
    return MergeSemantics(
      child: Semantics(
        label: '$etiqueta: $textoValor',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(etiqueta, style: estilo)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  textoValor,
                  textAlign: TextAlign.end,
                  style: estilo.copyWith(
                    color: ColoresCampo.textoPrincipal.withValues(
                      alpha: OpacidadesCampo.casiPlena,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
