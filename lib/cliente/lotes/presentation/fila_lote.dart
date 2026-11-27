import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Un lote del cliente: nombre, «zona · cultivo» y las hectáreas en mono.
/// Se usa en la pestaña Lotes y en «Mis campos» del perfil.
class FilaLote extends StatelessWidget {
  const FilaLote({required this.lote, super.key});

  final Lote lote;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final hectareas = t.perfilHectareasUnidad(
      FormatoMarketplace.hectareasNumero(lote.hectareas),
    );
    return Semantics(
      container: true,
      label:
          '${lote.nombre}, ${t.lotesLoteDetalle(lote.zona, lote.cultivo)}, '
          '$hectareas',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.m),
        child: Row(
          children: [
            Container(
              width: ObjetivoTactilCampo.minimo,
              height: ObjetivoTactilCampo.minimo,
              decoration: BoxDecoration(
                color: paleta.acentoContenedor,
                borderRadius: BorderRadius.circular(RadioCampo.media),
              ),
              child: Icon(
                Icons.landscape_rounded,
                color: paleta.sobreAcentoContenedor,
              ),
            ),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lote.nombre,
                    style: texto.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    t.lotesLoteDetalle(lote.zona, lote.cultivo),
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: EspaciadoCampo.s),
            Text(
              hectareas,
              style: TipografiaCampo.datoMonoDestacado.copyWith(
                color: paleta.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
