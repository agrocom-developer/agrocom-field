import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'mis_ofertas_cubit.dart';
import 'pedir_precio_hoja.dart';

/// La pestaña «Ofertas»: las ofertas del piloto con su estado y, cuando el
/// cliente contraoferta, las acciones para aceptar, contraofertar o
/// rechazar.
class MisOfertasPantalla extends StatelessWidget {
  const MisOfertasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MisOfertasCubit(context.read<NegociacionRepositorio>())..cargar(),
      child: const MisOfertasVista(),
    );
  }
}

class MisOfertasVista extends StatelessWidget {
  const MisOfertasVista({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<MisOfertasCubit, MisOfertasEstado>(
      builder: (context, estado) {
        final cubit = context.read<MisOfertasCubit>();
        return RefreshIndicator(
          onRefresh: cubit.cargar,
          child: ListView(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            children: [
              Text('Mis ofertas', style: texto.headlineMedium),
              const SizedBox(height: EspaciadoCampo.l),
              if (estado.aviso != null) ...[
                Semantics(
                  liveRegion: true,
                  child: AvisoMarketplace(
                    mensaje: estado.aviso!,
                    tono: estado.avisoEsError
                        ? TonoAviso.alerta
                        : TonoAviso.info,
                    icono: estado.avisoEsError
                        ? null
                        : Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              switch (estado.estado) {
                EstadoMisOfertas.cargando => const Column(
                  children: [
                    EsqueletoCampo(alto: 150, radio: 18),
                    SizedBox(height: EspaciadoCampo.m),
                    EsqueletoCampo(alto: 150, radio: 18),
                  ],
                ),
                EstadoMisOfertas.sinRed => EstadoErrorMarketplace(
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
                EstadoMisOfertas.listo when estado.ofertas.isEmpty =>
                  const EstadoVacioMarketplace(
                    icono: Icons.handshake_outlined,
                    titulo: 'Todavía no hiciste ofertas',
                    detalle:
                        'Abre una solicitud en el mapa y acepta el precio del '
                        'cliente o propón el tuyo.',
                  ),
                EstadoMisOfertas.listo => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final o in estado.ordenadas) ...[
                      TarjetaMiOferta(
                        oferta: o,
                        ocupada: estado.enCurso == o.id,
                        bloqueada: estado.enCurso != null,
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                    ],
                  ],
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

/// Una oferta con su precio, su turno y las acciones que el servidor
/// permite.
class TarjetaMiOferta extends StatelessWidget {
  const TarjetaMiOferta({
    required this.oferta,
    this.ocupada = false,
    this.bloqueada = false,
    super.key,
  });

  final OfertaNegociada oferta;

  final bool ocupada;
  final bool bloqueada;

  Future<void> _contraofertar(BuildContext context) async {
    final cubit = context.read<MisOfertasCubit>();
    final p = await pedirPrecio(
      context,
      titulo: 'Tu contraoferta',
      hectareas: oferta.hectareas,
      precioReferencia: oferta.precioHa,
      etiquetaReferencia: 'El cliente pide',
    );
    if (p != null) {
      await cubit.contraofertar(oferta, precioHa: p.precioHa, nota: p.nota);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = oferta;
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final cubit = context.read<MisOfertasCubit>();
    final (tono, icono, etiqueta) = switch (o.estado) {
      EstadoOferta.vigente when o.esperaMiRespuesta => (
        TonoEstado.alerta,
        Icons.reply_rounded,
        'Te toca responder',
      ),
      EstadoOferta.vigente => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
        'Esperando al cliente',
      ),
      EstadoOferta.aceptada => (
        TonoEstado.exito,
        Icons.verified_rounded,
        'Adjudicada',
      ),
      EstadoOferta.rechazada => (
        TonoEstado.error,
        Icons.block_rounded,
        'Rechazada',
      ),
      _ => (TonoEstado.neutro, Icons.history_rounded, o.estado.etiqueta),
    };
    return SuperficieMarketplace(
      resaltada: o.esperaMiRespuesta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            o.zona == null
                ? 'Solicitud ${o.solicitudId}'
                : 'Solicitud en ${o.zona}',
            style: texto.titleLarge,
          ),
          if (o.lote != null)
            Text(
              o.lote!,
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
          const SizedBox(height: EspaciadoCampo.s),
          ChipEstadoMarketplace(etiqueta: etiqueta, tono: tono, icono: icono),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            '${o.autor == AutorOferta.cliente ? 'El cliente pide' : 'Ofreciste'} '
            '${FormatoMarketplace.bs(o.precioHa)} por ha',
            style: texto.titleMedium,
          ),
          Text(
            '${FormatoMarketplace.hectareas(o.hectareas)} · total '
            '${FormatoMarketplace.bs(o.monto)} · ronda ${o.numero}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          if (o.nota != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text('«${o.nota}»', style: texto.bodyMedium),
          ],
          if (o.estado.activa)
            Padding(
              padding: const EdgeInsets.only(top: EspaciadoCampo.s),
              child: Text(
                'Vence ${FormatoMarketplace.fechaConDia(o.venceEn)} '
                'a las ${FormatoMarketplace.hora(o.venceEn)}',
                style: texto.bodyMedium,
              ),
            ),
          if (o.esDefinitiva && o.esperaMiRespuesta)
            const Padding(
              padding: EdgeInsets.only(top: EspaciadoCampo.s),
              child: AvisoMarketplace(
                mensaje:
                    'Es la última oferta del cliente: o la aceptas o la '
                    'rechazas. Ya no hay más contraofertas.',
                tono: TonoAviso.alerta,
              ),
            ),
          if (o.esperaMiRespuesta) ...[
            const SizedBox(height: EspaciadoCampo.m),
            BotonPrincipalMarketplace(
              texto: 'Aceptar ${FormatoMarketplace.bs(o.precioHa)} por ha',
              cargando: ocupada,
              onPressed: bloqueada ? null : () => cubit.aceptar(o),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Row(
              children: [
                if (!o.esDefinitiva)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          ObjetivoTactilCampo.guantes,
                        ),
                      ),
                      onPressed: bloqueada
                          ? null
                          : () => _contraofertar(context),
                      child: const Text('Contraofertar'),
                    ),
                  ),
                if (!o.esDefinitiva) const SizedBox(width: EspaciadoCampo.s),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: bloqueada ? null : () => cubit.rechazar(o),
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ] else if (o.esperaAlCliente) ...[
            const SizedBox(height: EspaciadoCampo.s),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
              ),
              onPressed: bloqueada ? null : () => cubit.retirar(o),
              child: const Text('Retirar mi oferta'),
            ),
          ],
        ],
      ),
    );
  }
}
