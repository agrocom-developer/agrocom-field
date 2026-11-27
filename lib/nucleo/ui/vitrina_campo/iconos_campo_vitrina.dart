import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../componentes/icono_agrocom.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Vitrina del catálogo de íconos dedicados (ADR 0028): toda la flota de
/// drones en fila para comparar la silueta, y el resto del catálogo en
/// grilla. Datos constantes, como el resto de la vitrina.
class IconosCampoVitrina extends StatelessWidget {
  const IconosCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    const flota = [
      IconoAgrocomId.dronT10,
      IconoAgrocomId.dronT20,
      IconoAgrocomId.dronT25,
      IconoAgrocomId.dronT30,
      IconoAgrocomId.dronT40,
      IconoAgrocomId.dronT50,
    ];
    const resto = [
      IconoAgrocomId.pulverizadorTanque,
      IconoAgrocomId.lote,
      IconoAgrocomId.cultivo,
      IconoAgrocomId.bateria,
      IconoAgrocomId.mandoRc,
      IconoAgrocomId.hectarea,
      IconoAgrocomId.checkEquipo,
    ];
    return ColoredBox(
      color: paleta.fondo,
      child: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          Text('Íconos dedicados', style: texto.headlineMedium),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            'Siluetas propias del dominio: la flota de drones, el equipo y '
            'las medidas del marketplace.',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          Text('FLOTA AGRAS', style: texto.labelSmall),
          const SizedBox(height: EspaciadoCampo.m),
          Wrap(
            spacing: EspaciadoCampo.l,
            runSpacing: EspaciadoCampo.l,
            children: [
              for (final id in flota)
                _CeldaIcono(id: id, l10n: l10n, paleta: paleta),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          Text('EQUIPO Y MEDIDAS', style: texto.labelSmall),
          const SizedBox(height: EspaciadoCampo.m),
          Wrap(
            spacing: EspaciadoCampo.l,
            runSpacing: EspaciadoCampo.l,
            children: [
              for (final id in resto)
                _CeldaIcono(id: id, l10n: l10n, paleta: paleta),
            ],
          ),
        ],
      ),
    );
  }
}

class _CeldaIcono extends StatelessWidget {
  const _CeldaIcono({
    required this.id,
    required this.l10n,
    required this.paleta,
  });

  final IconoAgrocomId id;
  final AppLocalizations l10n;
  final PaletaCampo paleta;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: paleta.superficie,
              borderRadius: BorderRadius.circular(RadioCampo.media),
              border: Border.all(color: paleta.borde),
            ),
            child: IconoAgrocom(
              id,
              tamano: TamanoIconoCampo.grande,
              color: paleta.texto,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            id.etiquetaPorDefecto(l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
