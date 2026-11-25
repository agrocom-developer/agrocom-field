import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Pestañas segmentadas («Activas 3 · Ganadas 2 · Cerradas»): un carril de
/// superficie 2 con radio 18 y la opción elegida sobre una superficie
/// elevada. Lee la paleta activa, así que sirve en los tres modos.
///
/// Cada opción lleva su etiqueta y, si la hay, una cifra en mono. El alto es
/// 56 (72 en modo campo) y la etiqueta nunca se corta: con texto grande, la
/// fila crece.
class PestanasCampo<T> extends StatelessWidget {
  const PestanasCampo({
    required this.opciones,
    required this.seleccionada,
    required this.onSeleccionar,
    super.key,
  });

  /// Valor, etiqueta y cifra opcional de cada pestaña.
  final List<(T valor, String etiqueta, int? cifra)> opciones;
  final T seleccionada;
  final ValueChanged<T> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final alto = paleta.esCampo
        ? ObjetivoTactilCampo.campo
        : ObjetivoTactilCampo.guantes;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.superficie2,
        borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
        border: Border.all(color: paleta.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.xs),
        child: Row(
          children: [
            for (final (valor, etiqueta, cifra) in opciones)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: valor == seleccionada,
                  label: cifra == null ? etiqueta : '$etiqueta, $cifra',
                  excludeSemantics: true,
                  child: Material(
                    color: valor == seleccionada
                        ? ElevacionCampo.superficie(paleta, 2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(RadioCampo.media),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(RadioCampo.media),
                      onTap: () {
                        if (valor != seleccionada) HapticaCampo.seleccion();
                        onSeleccionar(valor);
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: alto),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EspaciadoCampo.xs,
                            ),
                            child: Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: etiqueta,
                                    style: TipografiaCampo.cuerpo.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: valor == seleccionada
                                          ? paleta.texto
                                          : paleta.textoSecundario,
                                    ),
                                  ),
                                  if (cifra != null)
                                    TextSpan(
                                      text: ' $cifra',
                                      style: TipografiaCampo.cifraUnidad
                                          .copyWith(
                                            color: valor == seleccionada
                                                ? paleta.texto
                                                : paleta.textoSecundario,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
