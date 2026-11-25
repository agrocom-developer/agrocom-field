import 'package:flutter/material.dart';

import '../../solicitudes/domain/solicitud.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Línea de tiempo de la solicitud: qué pasó, qué pasa ahora y qué sigue.
///
/// Solo la etapa en curso lleva su explicación; las demás quedan en una
/// línea para que la vista no compita con ella. Cuando una etapa cambia de
/// estado, su nodo y su conector cambian de color con una transición corta.
class LineaTiempoSolicitud extends StatelessWidget {
  const LineaTiempoSolicitud({required this.hitos, super.key});

  final List<HitoSolicitud> hitos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.comunAvanceSolicitud,
      child: Column(
        children: [
          for (var i = 0; i < hitos.length; i++)
            _Hito(
              key: ValueKey(hitos[i].clave),
              hito: hitos[i],
              ultimo: i == hitos.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Hito extends StatelessWidget {
  const _Hito({required this.hito, required this.ultimo, super.key});

  final HitoSolicitud hito;
  final bool ultimo;

  static const double _nodo = EspaciadoCampo.xl;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final duracion = MovimientoCampo.duracion(context, MovimientoCampo.media);
    final actual = hito.estado == EstadoHito.actual;
    final hecho = hito.estado == EstadoHito.hecho;
    final momento = hito.momento;

    return Semantics(
      label:
          '${hito.titulo}, ${switch (hito.estado) {
            EstadoHito.hecho => 'listo',
            EstadoHito.actual => 'en curso',
            EstadoHito.pendiente => 'pendiente',
          }}'
          '${actual ? '. ${hito.detalle}' : ''}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _nodo,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: duracion,
                    curve: MovimientoCampo.entrada,
                    width: _nodo,
                    height: _nodo,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Hecho: círculo verde con tilde. En curso: anillo ámbar
                      // (lo que pide atención). Pendiente: anillo vacío.
                      color: hecho ? paleta.acentoTexto : paleta.superficie,
                      border: Border.all(
                        color: hecho
                            ? paleta.acentoTexto
                            : actual
                            ? paleta.ambar
                            : paleta.bordeFuerte,
                        width: actual ? 3 : 2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: duracion,
                      switchInCurve: MovimientoCampo.entrada,
                      transitionBuilder: (hijo, animacion) => ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.6,
                          end: 1,
                        ).animate(animacion),
                        child: FadeTransition(opacity: animacion, child: hijo),
                      ),
                      child: switch (hito.estado) {
                        EstadoHito.hecho => Icon(
                          Icons.check_rounded,
                          key: const ValueKey('hecho'),
                          size: EspaciadoCampo.l,
                          color: paleta.fondo,
                        ),
                        EstadoHito.actual => const SizedBox.shrink(
                          key: ValueKey('actual'),
                        ),
                        EstadoHito.pendiente => const SizedBox.shrink(
                          key: ValueKey('pendiente'),
                        ),
                      },
                    ),
                  ),
                  if (!ultimo)
                    Expanded(
                      child: AnimatedContainer(
                        duration: duracion,
                        width: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: EspaciadoCampo.xs,
                        ),
                        color: hecho ? paleta.acentoTexto : paleta.borde,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: ultimo ? 0 : EspaciadoCampo.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: EspaciadoCampo.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          hito.titulo,
                          style: texto.bodyLarge?.copyWith(
                            color: hito.estado == EstadoHito.pendiente
                                ? paleta.textoSecundario
                                : paleta.texto,
                            fontWeight: actual
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        if (momento != null)
                          Text(
                            '${FormatoMarketplace.fechaCorta(momento)}, '
                            '${FormatoMarketplace.hora(momento)}',
                            style: texto.bodySmall?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          ),
                      ],
                    ),
                    // Sin `AnimatedSize`: dentro de `IntrinsicHeight` y con la
                    // pantalla tapada por otra ruta (sin tickers) el tamaño
                    // quedaba a medias y desbordaba la columna.
                    if (actual)
                      Padding(
                        padding: const EdgeInsets.only(top: EspaciadoCampo.xs),
                        child: Text(
                          hito.detalle,
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
