import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/aparicion_marketplace.dart';
import '../../marketplace/ui/estado_error_marketplace.dart';
import '../../marketplace/ui/estado_vacio_marketplace.dart';
import '../../marketplace/ui/formato_marketplace.dart';
import '../../ui/componentes/esqueleto_lista_campo.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../domain/aviso.dart';
import '../domain/canal_aviso.dart';
import '../domain/preferencias_canales.dart';
import 'bandeja_cubit.dart';
import 'canales_pantalla.dart';
import 'textos_canal.dart';

/// «Mis notificaciones»: los avisos de la cuenta, los no leídos primero, con
/// un grupo por canal. Sin push, esta lista es por donde llegan las
/// oleadas, las ofertas y los mensajes. Maestro-detalle: tocar un aviso lo
/// marca como leído y entrega [alAbrir] para que la app abra el recurso.
class BandejaPantalla extends StatelessWidget {
  const BandejaPantalla({
    this.alAbrir,
    this.reloj,
    this.preferencias,
    super.key,
  });

  /// Dónde se guardan los ajustes de canal; por defecto, el del teléfono.
  final PreferenciasCanalesStore? preferencias;

  /// Qué hacer al tocar un aviso (abrir la solicitud, la oferta...). Sin él,
  /// solo se marca como leído.
  final void Function(Aviso aviso)? alAbrir;

  /// Reloj para «hace 5 min»; en pruebas, uno fijo.
  final DateTime Function()? reloj;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.avisosTitulo),
        actions: [
          IconButton(
            key: const ValueKey('avisos-ajustes'),
            tooltip: l10n.avisosAjustesCanales,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CanalesPantalla(store: preferencias),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _Cuerpo(alAbrir: alAbrir, reloj: reloj ?? DateTime.now),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.alAbrir, required this.reloj});

  final void Function(Aviso aviso)? alAbrir;
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BandejaCubit>();
    return BlocBuilder<BandejaCubit, BandejaEstado>(
      builder: (context, estado) {
        switch (estado.fase) {
          case FaseBandeja.cargando:
            return const Padding(
              padding: EdgeInsets.all(EspaciadoCampo.l),
              child: EsqueletoListaCampo(
                bloques: [
                  BloqueEsqueleto(alto: 72, radio: 16),
                  BloqueEsqueleto(alto: 72, radio: 16),
                  BloqueEsqueleto(alto: 72, radio: 16),
                  BloqueEsqueleto(alto: 72, radio: 16),
                ],
              ),
            );
          case FaseBandeja.error:
            return ListView(
              children: [
                EstadoErrorMarketplace(
                  titulo: l10n.avisosErrorTitulo,
                  detalle: l10n.avisosErrorDetalle,
                  sinConexion: estado.sinRed,
                  onReintentar: cubit.cargar,
                ),
              ],
            );
          case FaseBandeja.lista:
            final visibles = estado.visibles;
            return Column(
              children: [
                _Grupos(estado: estado),
                if (estado.refrescando)
                  const LinearProgressIndicator(
                    key: ValueKey('bandeja-refrescando'),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: cubit.cargar,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EstadoVacioMarketplace(
                                icono: Icons.notifications_none_rounded,
                                titulo: estado.canal == null
                                    ? l10n.avisosVacioTitulo
                                    : l10n.avisosVacioCanal,
                                detalle: estado.canal == null
                                    ? l10n.avisosVacioDetalle
                                    : null,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              EspaciadoCampo.l,
                              EspaciadoCampo.s,
                              EspaciadoCampo.l,
                              EspaciadoCampo.xl,
                            ),
                            itemCount: visibles.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: EspaciadoCampo.s),
                            itemBuilder: (context, i) => AparicionMarketplace(
                              orden: i,
                              child: _FilaAviso(
                                aviso: visibles[i],
                                ahora: reloj(),
                                alTocar: () {
                                  cubit.marcarLeida(visibles[i]);
                                  alAbrir?.call(visibles[i]);
                                },
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
        }
      },
    );
  }
}

/// Los grupos por canal, con los no leídos de cada uno.
class _Grupos extends StatelessWidget {
  const _Grupos({required this.estado});

  final BandejaEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BandejaCubit>();
    return SizedBox(
      height: ObjetivoTactilCampo.guantes,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: EspaciadoCampo.s),
            child: ChoiceChip(
              key: const ValueKey('grupo-todos'),
              label: Text(l10n.avisosTodos),
              selected: estado.canal == null,
              onSelected: (_) => cubit.elegirCanal(null),
            ),
          ),
          for (final c in CanalAviso.values)
            Padding(
              padding: const EdgeInsets.only(right: EspaciadoCampo.s),
              child: ChoiceChip(
                key: ValueKey('grupo-${c.codigo}'),
                avatar: Icon(c.icono, size: 18),
                label: Text(
                  estado.bandeja.noLeidasDelCanal(c) == 0
                      ? c.nombre(l10n)
                      : '${c.nombre(l10n)} · ${estado.bandeja.noLeidasDelCanal(c)}',
                ),
                selected: estado.canal == c,
                onSelected: (_) => cubit.elegirCanal(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({
    required this.aviso,
    required this.ahora,
    required this.alTocar,
  });

  final Aviso aviso;
  final DateTime ahora;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final canal = aviso.canal;
    final etiqueta =
        '${canal.nombre(l10n)}. ${aviso.titulo}. '
        '${FormatoMarketplace.hace(aviso.creadaEn, ahora)}. '
        '${aviso.leida ? l10n.avisosLeida : l10n.avisosSinLeer}';
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: Material(
        color: aviso.leida ? paleta.superficie : paleta.acentoContenedor,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: InkWell(
          key: ValueKey('aviso-${aviso.id}'),
          borderRadius: BorderRadius.circular(RadioCampo.media),
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes,
            ),
            child: Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    canal.icono,
                    color: aviso.leida
                        ? paleta.textoSecundario
                        : paleta.acentoTexto,
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aviso.titulo,
                          style: aviso.leida
                              ? texto.bodyLarge
                              : texto.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                        const SizedBox(height: EspaciadoCampo.xs),
                        Text(
                          '${canal.nombre(l10n)} · '
                          '${FormatoMarketplace.hace(aviso.creadaEn, ahora)}',
                          style: texto.bodySmall?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!aviso.leida) ...[
                    const SizedBox(width: EspaciadoCampo.s),
                    // El punto acompaña a la negrita y al texto semántico:
                    // no se depende solo del color.
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: paleta.acentoTexto,
                      semanticLabel: l10n.avisosSinLeer,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
