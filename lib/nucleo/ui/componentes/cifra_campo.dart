import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';

/// Cifra de negocio en JetBrains Mono con su unidad ("42,5" + "ha"). Toda
/// cantidad que el usuario compara (hectáreas, Bs/ha, totales, rondas) pasa
/// por aquí o usa los estilos `cifra*` de [TipografiaCampo].
///
/// Recibe el valor ya formateado (miles con punto, decimal con coma): el
/// dinero y las hectáreas nunca viajan como `double`.
class CifraCampo extends StatelessWidget {
  const CifraCampo({
    required this.valor,
    this.unidad,
    this.estilo = TipografiaCampo.cifraGrande,
    this.color,
    super.key,
  });

  final String valor;
  final String? unidad;

  /// Uno de los estilos `cifra*` de [TipografiaCampo].
  final TextStyle estilo;

  /// Color del valor; por defecto el texto de la paleta.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final colorValor = color ?? paleta.texto;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: valor,
            style: estilo.copyWith(color: colorValor),
          ),
          if (unidad != null)
            TextSpan(
              text: ' $unidad',
              style: TipografiaCampo.cifraUnidad.copyWith(
                color: color ?? paleta.textoSecundario,
              ),
            ),
        ],
      ),
    );
  }
}
