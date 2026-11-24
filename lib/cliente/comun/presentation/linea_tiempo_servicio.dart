import 'package:flutter/material.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Línea de tiempo del servicio: qué pasó, qué pasa ahora y qué sigue.
///
/// Solo la etapa en curso lleva su explicación; las demás quedan en una
/// línea para que la vista no compita con ella. Cuando una etapa cambia de
/// estado, su nodo y su conector cambian de color con una transición corta.
class LineaTiempoServicio extends StatelessWidget {
  const LineaTiempoServicio({required this.hitos, super.key});

  final List<HitoServicio> hitos;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Estado del servicio',
      child: Column(
        children: [
          for (var i = 0; i < hitos.length; i++)
            _Hito(
              key: ValueKey(hitos[i].etapa),
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

  final HitoServicio hito;
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
                      color: hecho
                          ? paleta.acentoTexto
                          : actual
                          ? paleta.acento
                          : paleta.superficie,
                      border: Border.all(
                        color: hecho || actual
                            ? paleta.acentoTexto
                            : paleta.bordeFuerte,
                        width: 2,
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
                        EstadoHito.actual => Icon(
                          Icons.circle,
                          key: const ValueKey('actual'),
                          size: EspaciadoCampo.s,
                          color: paleta.sobreAcento,
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
                          style: (actual ? texto.titleMedium : texto.bodyLarge)
                              ?.copyWith(
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
                    AnimatedSize(
                      duration: duracion,
                      curve: MovimientoCampo.movimiento,
                      alignment: Alignment.topLeft,
                      child: actual
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: EspaciadoCampo.xs,
                              ),
                              child: Text(
                                hito.detalle,
                                style: texto.bodyMedium?.copyWith(
                                  color: paleta.textoSecundario,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
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
