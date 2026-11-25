import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tipografia_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'cifras_negociacion.dart';
import 'mis_ofertas_cubit.dart';
import 'negociacion_pantalla.dart';

/// La pestaña «Ofertas» (pantalla 16): una tarjeta por negociación con lo
/// último que pidió el cliente y lo último que ofreciste. La que espera tu
/// respuesta lleva borde ámbar y va primero. Tocar una tarjeta abre la
/// conversación, donde se acepta, se contraoferta o se rechaza.
class MisOfertasPantalla extends StatelessWidget {
  const MisOfertasPantalla({this.alIrAlMapa, super.key});

  /// Salida del estado vacío: llevar al mapa de solicitudes.
  final VoidCallback? alIrAlMapa;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MisOfertasCubit(context.read<NegociacionRepositorio>())..cargar(),
      child: MisOfertasVista(alIrAlMapa: alIrAlMapa),
    );
  }
}

enum _Pestana { activas, ganadas, cerradas }

class MisOfertasVista extends StatefulWidget {
  const MisOfertasVista({this.alIrAlMapa, super.key});

  final VoidCallback? alIrAlMapa;

  @override
  State<MisOfertasVista> createState() => _MisOfertasVistaState();
}

class _MisOfertasVistaState extends State<MisOfertasVista> {
  _Pestana _pestana = _Pestana.activas;

  Future<void> _abrir(ResumenNegociacion n) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NegociacionPantalla(solicitudId: n.solicitudId),
      ),
    );
    if (mounted) context.read<MisOfertasCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return BlocBuilder<MisOfertasCubit, MisOfertasEstado>(
      builder: (context, estado) {
        final cubit = context.read<MisOfertasCubit>();
        final listo = estado.estado == EstadoMisOfertas.listo;
        final visibles = switch (_pestana) {
          _Pestana.activas => estado.activas,
          _Pestana.ganadas => estado.ganadas,
          _Pestana.cerradas => estado.cerradas,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (estado.estado == EstadoMisOfertas.sinRed ||
                (estado.aviso != null && estado.avisoEsError))
              BannerSinSenalCampo(
                mensaje: estado.estado == EstadoMisOfertas.sinRed
                    ? 'tus ofertas se ven con red.'
                    : 'lo que ves puede estar viejo.',
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.cargar,
                child: ListView(
                  padding: const EdgeInsets.all(EspaciadoCampo.l),
                  children: [
                    Text(
                      'Mis ofertas',
                      style: TipografiaCampo.tituloPantalla.copyWith(
                        color: paleta.texto,
                      ),
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    PestanasCampo<_Pestana>(
                      seleccionada: _pestana,
                      onSeleccionar: (p) => setState(() => _pestana = p),
                      opciones: [
                        (
                          _Pestana.activas,
                          'Activas',
                          listo ? estado.activas.length : null,
                        ),
                        (
                          _Pestana.ganadas,
                          'Ganadas',
                          listo ? estado.ganadas.length : null,
                        ),
                        (_Pestana.cerradas, 'Cerradas', null),
                      ],
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    if (estado.aviso != null && !estado.avisoEsError) ...[
                      Semantics(
                        liveRegion: true,
                        child: AvisoMarketplace(
                          mensaje: estado.aviso!,
                          icono: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                    ],
                    switch (estado.estado) {
                      EstadoMisOfertas.cargando => const Column(
                        children: [
                          EsqueletoCampo(alto: 148, radio: 24),
                          SizedBox(height: EspaciadoCampo.m),
                          EsqueletoCampo(alto: 148, radio: 24),
                        ],
                      ),
                      EstadoMisOfertas.sinRed => EstadoErrorMarketplace(
                        sinConexion: true,
                        tablaSinRed: true,
                        titulo: 'Sin conexión',
                        detalle:
                            'Para ver y responder tus ofertas necesitas señal. '
                            'Reintenta cuando la tengas.',
                        onReintentar: cubit.cargar,
                      ),
                      EstadoMisOfertas.error => EstadoErrorMarketplace(
                        titulo: 'No pudimos cargar tus ofertas',
                        detalle: 'Intenta de nuevo en un momento.',
                        onReintentar: cubit.cargar,
                      ),
                      EstadoMisOfertas.listo when visibles.isEmpty => _Vacio(
                        hayOfertas: estado.ofertas.isNotEmpty,
                        pestana: _pestana,
                        alIrAlMapa: widget.alIrAlMapa,
                      ),
                      EstadoMisOfertas.listo => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (estado.aviso != null && estado.avisoEsError) ...[
                            AvisoMarketplace(
                              mensaje: estado.aviso!,
                              tono: TonoAviso.alerta,
                            ),
                            const SizedBox(height: EspaciadoCampo.m),
                          ],
                          for (final n in visibles) ...[
                            TarjetaNegociacion(
                              negociacion: n,
                              alToque: () => _abrir(n),
                            ),
                            const SizedBox(height: EspaciadoCampo.m),
                          ],
                        ],
                      ),
                    },
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.hayOfertas,
    required this.pestana,
    required this.alIrAlMapa,
  });

  final bool hayOfertas;
  final _Pestana pestana;
  final VoidCallback? alIrAlMapa;

  @override
  Widget build(BuildContext context) {
    final (icono, titulo, detalle) = !hayOfertas
        ? (
            Icons.handshake_outlined,
            'Todavía no hiciste ofertas',
            'Abre una solicitud en el mapa y acepta el precio del cliente o '
                'propón el tuyo.',
          )
        : switch (pestana) {
            _Pestana.activas => (
              Icons.hourglass_empty_rounded,
              'No tienes negociaciones activas',
              'Cuando ofertes en el mapa, la conversación aparece aquí.',
            ),
            _Pestana.ganadas => (
              Icons.emoji_events_outlined,
              'Aún no ganaste ninguna',
              'Las solicitudes en las que el cliente te elige quedan aquí.',
            ),
            _Pestana.cerradas => (
              Icons.inventory_2_outlined,
              'Nada cerrado todavía',
              'Las ofertas rechazadas, retiradas o vencidas se guardan aquí.',
            ),
          };
    return EstadoVacioMarketplace(
      icono: icono,
      titulo: titulo,
      detalle: detalle,
      etiquetaAccion: alIrAlMapa == null
          ? null
          : AppLocalizations.of(context).listaVerLotesMapa,
      alAccion: alIrAlMapa,
    );
  }
}

/// Una negociación: el lote, su estado y las dos cifras que importan, lo
/// último que pide el cliente y lo último que ofreciste. Con borde ámbar si
/// es tu turno.
class TarjetaNegociacion extends StatelessWidget {
  const TarjetaNegociacion({
    required this.negociacion,
    required this.alToque,
    super.key,
  });

  final ResumenNegociacion negociacion;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final n = negociacion;
    final o = n.ultima;
    final paleta = context.paleta;
    final cliente = n.ultimaDelCliente;
    final mia = n.ultimaMia;
    final (tono, icono, etiqueta) = switch (o.estado) {
      EstadoOferta.vigente when n.esMiTurno => (
        TonoEstado.alerta,
        Icons.reply_rounded,
        'Tu turno · R${n.rondaQueSigue}/5',
      ),
      EstadoOferta.vigente => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
        'Esperando · R${n.rondaQueSigue}/5',
      ),
      EstadoOferta.aceptada => (
        TonoEstado.exito,
        Icons.verified_rounded,
        'Aceptada',
      ),
      EstadoOferta.rechazada => (
        TonoEstado.error,
        Icons.block_rounded,
        'Rechazada',
      ),
      _ => (TonoEstado.neutro, Icons.history_rounded, o.estado.etiqueta),
    };
    final titulo = o.lote ?? (n.zona ?? 'Solicitud ${o.solicitudId}');
    final detalle = [
      '${CifrasNegociacion.ha(o.hectareas)} ha',
      if (n.zona != null && o.lote != null) n.zona!,
    ].join(' · ');
    return Semantics(
      button: true,
      label:
          '$titulo, $detalle, $etiqueta'
          '${cliente == null ? '' : ', cliente ${CifrasNegociacion.bsHa(cliente.precioHa)} bolivianos por hectárea'}'
          '${mia == null ? '' : ', tú ${CifrasNegociacion.bsHa(mia.precioHa)}'}',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        onTap: alToque,
        radio: RadioCampo.tarjeta,
        colorBorde: n.esMiTurno ? paleta.ambar : null,
        padding: const EdgeInsets.all(EspaciadoCampo.l + EspaciadoCampo.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: EspaciadoCampo.m,
              runSpacing: EspaciadoCampo.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  titulo,
                  style: TipografiaCampo.tituloBloque.copyWith(
                    fontSize: 20,
                    color: paleta.texto,
                  ),
                ),
                ChipEstadoMarketplace(
                  etiqueta: etiqueta,
                  tono: tono,
                  icono: icono,
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              detalle,
              style: TipografiaCampo.cuerpoSecundario.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Wrap(
              spacing: EspaciadoCampo.xl,
              runSpacing: EspaciadoCampo.s,
              children: [
                if (cliente != null)
                  _Cifra(etiqueta: 'Cliente', valor: cliente.precioHa),
                if (mia != null) _Cifra(etiqueta: 'Tú', valor: mia.precioHa),
              ],
            ),
            if (n.activa) ...[
              const SizedBox(height: EspaciadoCampo.m),
              Text(
                'Vence ${FormatoMarketplace.fechaConDia(o.venceEn)} '
                'a las ${FormatoMarketplace.hora(o.venceEn)}',
                style: TipografiaCampo.cuerpoSecundario.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.valor});

  final String etiqueta;
  final Decimal valor;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TipografiaCampo.cuerpoSecundario.copyWith(
            color: paleta.textoSecundario,
          ),
        ),
        CifraCampo(
          valor: CifrasNegociacion.bsHa(valor),
          unidad: 'Bs/ha',
          estilo: TipografiaCampo.cifraGrande,
        ),
      ],
    );
  }
}
