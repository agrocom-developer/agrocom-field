import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/marketplace_ui.dart';
import '../../../ui/componentes/componentes_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/bandeja_repositorio.dart';
import '../domain/notificacion.dart';
import 'bandeja_cubit.dart';

/// Bandeja de notificaciones: los mensajes entre cliente y piloto y los
/// avisos del sistema, los más recientes primero y agrupados por día. Lee
/// [BandejaRepositorio] del contexto. Abrir un aviso lo marca como leído.
class BandejaNotificacionesPantalla extends StatelessWidget {
  const BandejaNotificacionesPantalla({this.reloj = DateTime.now, super.key});

  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BandejaCubit(context.read<BandejaRepositorio>())..cargar(),
      child: _Vista(reloj: reloj),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.reloj});

  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estado = context.watch<BandejaCubit>().state;
    final hayNoLeidas = estado is BandejaLista && estado.noLeidas > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.bandejaTitulo),
        actions: [
          if (hayNoLeidas)
            IconButton(
              key: const Key('bandeja-marcar-todas'),
              tooltip: t.bandejaMarcarTodas,
              icon: const Icon(Icons.done_all_rounded),
              onPressed: context.read<BandejaCubit>().marcarTodasLeidas,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
        child: switch (estado) {
          BandejaCargando() => const _Cargando(key: ValueKey('cargando')),
          BandejaError(:final sinConexion) => EstadoErrorMarketplace(
            key: const ValueKey('error'),
            titulo: t.bandejaErrorTitulo,
            detalle: t.bandejaErrorDetalle,
            sinConexion: sinConexion,
            onReintentar: context.read<BandejaCubit>().cargar,
          ),
          BandejaLista() => _Lista(
            key: const ValueKey('lista'),
            estado: estado,
            ahora: reloj(),
          ),
        },
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++) ...[
          const Row(
            children: [
              EsqueletoCampo(ancho: 44, alto: 44, radio: 22),
              SizedBox(width: EspaciadoCampo.m),
              Expanded(child: EsqueletoCampo(alto: 52)),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.l),
        ],
      ],
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado, required this.ahora, super.key});

  final BandejaLista estado;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<BandejaCubit>();
    final visibles = [...estado.visibles]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return Column(
      children: [
        _Filtros(actual: estado.filtro, alElegir: cubit.filtrar),
        Expanded(
          child: visibles.isEmpty
              ? _Vacia(filtro: estado.filtro)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    EspaciadoCampo.l,
                    EspaciadoCampo.s,
                    EspaciadoCampo.l,
                    EspaciadoCampo.xl,
                  ),
                  children: EntradaCampo.escalonar([
                    for (final grupo in _grupos(visibles, ahora, t)) ...[
                      _TituloGrupo(grupo.titulo),
                      SuperficieMarketplace(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < grupo.avisos.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  indent: EspaciadoCampo.l,
                                  endIndent: EspaciadoCampo.l,
                                  color: context.paleta.borde,
                                ),
                              _Fila(
                                aviso: grupo.avisos[i],
                                ahora: ahora,
                                alToque: () => cubit.abrir(grupo.avisos[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                    ],
                  ]),
                ),
        ),
      ],
    );
  }

  static List<({String titulo, List<Notificacion> avisos})> _grupos(
    List<Notificacion> avisos,
    DateTime ahora,
    AppLocalizations t,
  ) {
    DateTime dia(DateTime f) => DateTime(f.year, f.month, f.day);
    final hoy = dia(ahora);
    final ayer = hoy.subtract(const Duration(days: 1));
    final hoyLista = <Notificacion>[];
    final ayerLista = <Notificacion>[];
    final antes = <Notificacion>[];
    for (final a in avisos) {
      final d = dia(a.fecha);
      if (!d.isBefore(hoy)) {
        hoyLista.add(a);
      } else if (d == ayer) {
        ayerLista.add(a);
      } else {
        antes.add(a);
      }
    }
    return [
      if (hoyLista.isNotEmpty) (titulo: t.bandejaGrupoHoy, avisos: hoyLista),
      if (ayerLista.isNotEmpty) (titulo: t.bandejaGrupoAyer, avisos: ayerLista),
      if (antes.isNotEmpty) (titulo: t.bandejaGrupoAntes, avisos: antes),
    ];
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.actual, required this.alElegir});

  final FiltroBandeja actual;
  final ValueChanged<FiltroBandeja> alElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final opciones = [
      (FiltroBandeja.todas, t.bandejaFiltroTodas),
      (FiltroBandeja.mensajes, t.bandejaFiltroMensajes),
      (FiltroBandeja.sistema, t.bandejaFiltroSistema),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: EspaciadoCampo.s,
          children: [
            for (final (filtro, etiqueta) in opciones)
              ChoiceChip(
                key: Key('bandeja-filtro-${filtro.name}'),
                label: Text(etiqueta),
                selected: filtro == actual,
                onSelected: (_) => alElegir(filtro),
                showCheckmark: false,
                labelStyle: texto.labelLarge?.copyWith(
                  color: filtro == actual ? paleta.sobreCabecera : paleta.texto,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: paleta.cabecera,
                backgroundColor: paleta.superficie2,
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: EspaciadoCampo.m,
        bottom: EspaciadoCampo.s,
      ),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.aviso,
    required this.ahora,
    required this.alToque,
  });

  final Notificacion aviso;
  final DateTime ahora;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cuando = FormatoMarketplace.hace(aviso.fecha, ahora);
    final noLeida = !aviso.leida;
    final remitente = switch (aviso.origen) {
      OrigenPersona(:final nombre) => nombre,
      OrigenSistema() => t.bandejaOrigenSistema,
    };
    return Semantics(
      button: true,
      container: true,
      label:
          '${noLeida ? '${t.bandejaNoLeida}. ' : ''}$remitente. '
          '${aviso.titulo}. ${aviso.cuerpo}. $cuando',
      excludeSemantics: true,
      onTap: alToque,
      child: InkWell(
        key: Key('bandeja-aviso-${aviso.id}'),
        onTap: alToque,
        borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes,
          ),
          child: Padding(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(origen: aviso.origen),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aviso.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: texto.titleMedium?.copyWith(
                          fontWeight: noLeida
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (aviso.cuerpo.isNotEmpty) ...[
                        const SizedBox(height: EspaciadoCampo.xs),
                        Text(
                          aviso.cuerpo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cuando,
                      style: texto.bodySmall?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    if (noLeida)
                      Container(
                        key: Key('bandeja-punto-${aviso.id}'),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: paleta.ambar,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.origen});

  final OrigenNotificacion origen;

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final primera = partes.first.isEmpty ? '' : partes.first[0];
    final segunda = partes.length > 1 ? partes[1][0] : '';
    return (primera + segunda).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ExcludeSemantics(
      child: switch (origen) {
        OrigenSistema() => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: paleta.cabecera,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.eco_rounded, color: paleta.sobreCabecera),
        ),
        OrigenPersona(:final nombre) => Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: paleta.acentoContenedor,
            shape: BoxShape.circle,
          ),
          child: Text(
            _iniciales(nombre),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: paleta.sobreAcentoContenedor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      },
    );
  }
}

class _Vacia extends StatelessWidget {
  const _Vacia({required this.filtro});

  final FiltroBandeja filtro;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (icono, titulo, detalle) = switch (filtro) {
      FiltroBandeja.todas => (
        Icons.notifications_none_rounded,
        t.bandejaVacioTitulo,
        t.bandejaVacioDetalle,
      ),
      FiltroBandeja.mensajes => (
        Icons.chat_bubble_outline_rounded,
        t.bandejaVacioMensajesTitulo,
        t.bandejaVacioMensajesDetalle,
      ),
      FiltroBandeja.sistema => (
        Icons.eco_outlined,
        t.bandejaVacioSistemaTitulo,
        t.bandejaVacioSistemaDetalle,
      ),
    };
    return EstadoVacioMarketplace(
      icono: icono,
      titulo: titulo,
      detalle: detalle,
    );
  }
}
