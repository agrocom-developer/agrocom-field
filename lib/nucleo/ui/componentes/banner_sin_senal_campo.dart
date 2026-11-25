import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Banner de red para la parte superior de una pantalla: fondo ámbar y texto
/// «Sin señal · [mensaje]». Dice qué se guardó y qué espera a la red; el
/// ícono y el texto portan el significado, no solo el color.
class BannerSinSenalCampo extends StatelessWidget {
  const BannerSinSenalCampo({required this.mensaje, this.titulo, super.key});

  /// Encabezado del aviso; por omisión, «Sin señal».
  final String? titulo;

  /// Lo que pasa sin red ("tus ofertas se guardan y se envían al volver").
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final titulo =
        this.titulo ?? AppLocalizations.of(context).componentesSinSenal;
    final paleta = context.paleta;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$titulo. $mensaje',
      excludeSemantics: true,
      child: ColoredBox(
        color: paleta.ambar,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.l,
              vertical: EspaciadoCampo.s + 2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.signal_wifi_off_rounded,
                  size: 18,
                  color: paleta.sobreAmbar,
                ),
                const SizedBox(width: EspaciadoCampo.s),
                Expanded(
                  child: Text(
                    '$titulo · $mensaje',
                    style: TipografiaCampo.etiqueta.copyWith(
                      color: paleta.sobreAmbar,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
