import 'package:flutter/material.dart';

import '../../marketplace/ui/superficie_marketplace.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Bloque de cifras del perfil (p. ej. «2 lotes · 6 servicios · 5,0»): una
/// sola tarjeta con columnas iguales y centradas. Es el mismo bloque en
/// `cliente` y `piloto`. Con el texto al 200 % pasa a una columna para no
/// cortar las etiquetas.
class CifrasPerfilCampo extends StatelessWidget {
  const CifrasPerfilCampo({required this.cifras, super.key});

  final List<({String valor, String etiqueta})> cifras;

  @override
  Widget build(BuildContext context) {
    final grande = MediaQuery.textScalerOf(context).scale(10) > 15;
    final celdas = [
      for (final c in cifras) _Cifra(valor: c.valor, etiqueta: c.etiqueta),
    ];
    return SuperficieMarketplace(
      child: grande
          ? Column(
              children: [
                for (var i = 0; i < celdas.length; i++) ...[
                  if (i > 0) const SizedBox(height: EspaciadoCampo.l),
                  celdas[i],
                ],
              ],
            )
          : Row(children: [for (final c in celdas) Expanded(child: c)]),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return MergeSemantics(
      child: Column(
        children: [
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TipografiaCampo.cifraMedia.copyWith(color: paleta.texto),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          // Un solo estilo y siempre en minúscula, en las dos apps.
          Text(
            etiqueta.toLowerCase(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}
