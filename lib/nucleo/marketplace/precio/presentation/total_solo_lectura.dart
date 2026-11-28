import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/formato_marketplace.dart';

/// El total estimado de solo lectura: hectáreas por precio por hectárea. Se
/// recalcula mientras se escribe el precio y nunca se envía al servidor, que
/// lo calcula por su lado (`monto_estimado`).
class TotalSoloLectura extends StatelessWidget {
  const TotalSoloLectura({
    required this.hectareas,
    required this.precioHa,
    super.key,
  });

  final Decimal hectareas;

  /// `null` mientras no hay un precio válido escrito.
  final Decimal? precioHa;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final total = precioHa == null ? null : hectareas * precioHa!;
    final valor = total == null
        ? l10n.precioTotalSinPrecio
        : FormatoMarketplace.bs(total);
    final detalle = total == null
        ? l10n.precioTotalSoloLectura
        : l10n.precioTotalCalculo(
            FormatoMarketplace.hectareas(hectareas),
            FormatoMarketplace.bs(precioHa!),
          );
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${l10n.precioTotalEtiqueta}: $valor. $detalle',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('total-solo-lectura'),
        padding: const EdgeInsets.all(EspaciadoCampo.m),
        decoration: BoxDecoration(
          color: paleta.superficieElevada,
          borderRadius: BorderRadius.circular(RadioCampo.media),
          border: Border.all(color: paleta.borde),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: paleta.textoSecundario),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.precioTotalEtiqueta,
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  Text(valor, style: texto.titleLarge),
                  Text(
                    detalle,
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
