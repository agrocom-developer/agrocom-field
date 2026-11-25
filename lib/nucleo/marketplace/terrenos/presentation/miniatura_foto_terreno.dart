import 'package:flutter/material.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import 'fotos_terreno_estado.dart';
import 'imagen_terreno.dart';
import '../../../../l10n/app_localizations.dart';

/// Lado de una miniatura: cabe tres por fila en un teléfono chico.
const double ladoMiniaturaFoto = 96;

/// Una foto del terreno con su estado (subiendo, pendiente, fallida) y la
/// acción de quitarla.
class MiniaturaFotoTerreno extends StatelessWidget {
  const MiniaturaFotoTerreno({
    required this.foto,
    required this.numero,
    required this.alQuitar,
    required this.alReintentar,
    this.alAbrir,
    super.key,
  });

  final FotoDeTerreno foto;
  final int numero;
  final VoidCallback? alAbrir;
  final VoidCallback alQuitar;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final fallida = foto.situacion == SituacionFoto.fallida;
    final subiendo = foto.situacion == SituacionFoto.subiendo;
    final estado = switch (foto.situacion) {
      SituacionFoto.guardada => 'guardada',
      SituacionFoto.subiendo => 'subiendo',
      SituacionFoto.pendiente => l10n.terrenosSubePublicar,
      SituacionFoto.fallida => l10n.terrenosPudoSubir,
    };
    return SizedBox.square(
      dimension: ladoMiniaturaFoto,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              image: true,
              button: alAbrir != null,
              label: l10n.terrenosFotoDelTerreno(numero, estado),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RadioCampo.media),
                child: InkWell(
                  onTap: fallida ? alReintentar : alAbrir,
                  child: ImagenTerreno(bytes: foto.bytes, url: foto.url),
                ),
              ),
            ),
          ),
          if (subiendo || fallida)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !fallida,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RadioCampo.media),
                    color: paleta.fondo.withValues(alpha: 0.7),
                    border: fallida
                        ? Border.all(color: paleta.error, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: subiendo
                        ? SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: paleta.acentoTexto,
                            ),
                          )
                        : InkWell(
                            key: Key('fotos-terreno-reintentar-$numero'),
                            onTap: alReintentar,
                            child: Padding(
                              padding: const EdgeInsets.all(EspaciadoCampo.s),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: paleta.error,
                                  ),
                                  Text(
                                    l10n.terrenosReintentar,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: paleta.texto),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          if (!subiendo)
            Positioned(
              top: -EspaciadoCampo.s,
              right: -EspaciadoCampo.s,
              child: Semantics(
                button: true,
                label: l10n.terrenosQuitarFoto(numero),
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: ObjetivoTactilCampo.minimo,
                  child: Center(
                    child: Material(
                      color: paleta.superficie,
                      shape: CircleBorder(
                        side: BorderSide(color: paleta.bordeFuerte),
                      ),
                      child: InkWell(
                        key: Key('fotos-terreno-quitar-$numero'),
                        customBorder: const CircleBorder(),
                        onTap: alQuitar,
                        child: Padding(
                          padding: const EdgeInsets.all(EspaciadoCampo.xs + 2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: paleta.texto,
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
    );
  }
}
