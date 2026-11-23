import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/marketplace_ui.dart';
import 'ofertas_cubit.dart';
import 'ofertas_estado.dart';
import 'ofertas_pantalla.dart';

/// Detalle de una oferta: el lote en el mapa, lo que hay que aplicar y
/// cuánto paga, con aceptar y rechazar anclados abajo. Lee el mismo
/// [OfertasCubit] de la bandeja, así la cuenta regresiva y el estado de red
/// son los mismos.
class OfertaDetallePantalla extends StatelessWidget {
  const OfertaDetallePantalla({required this.ofertaId, super.key});

  final String ofertaId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OfertasCubit, OfertasEstado>(
      // Respondida (aceptada o rechazada): ya no está ni vigente ni cerrada.
      listenWhen: (a, b) =>
          a.vigente(ofertaId) != null &&
          b.vigente(ofertaId) == null &&
          b.cerrada(ofertaId) == null,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, estado) {
        final oferta = estado.vigente(ofertaId);
        final cerrada = estado.cerrada(ofertaId);
        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de la oferta')),
          body: SafeArea(
            child: oferta != null
                ? _Vigente(oferta: oferta, estado: estado)
                : _NoDisponible(cerrada: cerrada),
          ),
        );
      },
    );
  }
}

class _Vigente extends StatelessWidget {
  const _Vigente({required this.oferta, required this.estado});

  final Oferta oferta;
  final OfertasEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<OfertasCubit>();
    final restante = oferta.restante(estado.ahora);
    final porVencer = restante.inSeconds <= 10;
    final respondiendo = estado.respondiendo.contains(oferta.id);
    final bloqueada = respondiendo || !estado.enLinea;
    final lote = oferta.lote;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 220,
                  child: MapaLote(lotes: [lote], seleccionado: lote),
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              if (oferta.esDeAgrocom) ...[
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ChipEstadoMarketplace(
                    etiqueta: 'Prioritaria · flota de Agrocom',
                    etiquetaSemantica:
                        'Asignación prioritaria, flota de Agrocom',
                    tono: TonoEstado.exito,
                    icono: Icons.verified_rounded,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              Text(
                '${FormatoMarketplace.hectareas(lote.hectareas)} · '
                '${lote.cultivo}',
                style: texto.headlineMedium,
              ),
              const SizedBox(height: EspaciadoCampo.xs),
              Text('${lote.nombre}, ${lote.zona}', style: texto.bodyLarge),
              const SizedBox(height: EspaciadoCampo.l),
              SuperficieMarketplace(
                child: Column(
                  children: [
                    _Fila(
                      etiqueta: 'Tiempo para responder',
                      valor: OfertaServicioCampo.textoRestante(restante),
                      color: porVencer ? paleta.error : paleta.acentoTexto,
                    ),
                    _Fila(
                      etiqueta: 'Pago estimado',
                      valor: FormatoMarketplace.bs(oferta.pago),
                    ),
                    _Fila(
                      etiqueta: 'Distancia',
                      valor: FormatoMarketplace.kilometros(oferta.distanciaKm),
                    ),
                    _Fila(
                      etiqueta: 'Fecha del servicio',
                      valor: FormatoMarketplace.fechaLarga(
                        oferta.fechaServicio,
                      ),
                    ),
                    _Fila(
                      etiqueta: 'Producto',
                      valor: oferta.producto,
                      ultima: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              const AvisoMarketplace(
                mensaje:
                    'El contacto del cliente y el acceso al lote se muestran '
                    'al aceptar. El pago es estimado y se liquida fuera de '
                    'la app.',
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: paleta.superficie,
            border: Border(top: BorderSide(color: paleta.borde)),
          ),
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!estado.enLinea) ...[
                Row(
                  key: const Key('detalle-sin-conexion'),
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 20,
                      color: paleta.alerta,
                    ),
                    const SizedBox(width: EspaciadoCampo.s),
                    Expanded(
                      child: Text(
                        'Sin conexión. Para responder necesitás red.',
                        style: texto.bodyMedium?.copyWith(color: paleta.texto),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              FilledButton(
                onPressed: bloqueada ? null : () => cubit.aceptar(oferta.id),
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: paleta.borde,
                  disabledForegroundColor: paleta.textoSecundario,
                ),
                child: Text(respondiendo ? 'Enviando…' : 'Aceptar servicio'),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              OutlinedButton(
                onPressed: bloqueada ? null : () => cubit.rechazar(oferta.id),
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: paleta.textoSecundario,
                ),
                child: const Text('Rechazar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.etiqueta,
    required this.valor,
    this.color,
    this.ultima = false,
  });

  final String etiqueta;
  final String valor;
  final Color? color;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.m),
      decoration: ultima
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: paleta.borde)),
            ),
      width: double.infinity,
      child: MergeSemantics(
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: EspaciadoCampo.l,
          runSpacing: EspaciadoCampo.xs,
          children: [
            Text(etiqueta, style: texto.bodyMedium),
            Text(
              valor,
              style: texto.titleLarge?.copyWith(color: color ?? paleta.texto),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDisponible extends StatelessWidget {
  const _NoDisponible({required this.cerrada});

  final OfertaCerrada? cerrada;

  @override
  Widget build(BuildContext context) {
    final c = cerrada;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EstadoVacioMarketplace(
          icono: c?.motivo == MotivoCierreOferta.tomada
              ? Icons.group_outlined
              : Icons.timer_off_outlined,
          titulo: switch (c?.motivo) {
            MotivoCierreOferta.tomada => 'Ya la tomó otro proveedor',
            MotivoCierreOferta.vencida => 'Oferta vencida',
            null => 'Esta oferta ya no está disponible',
          },
          detalle: c == null
              ? null
              : mensajeDeRespuesta(
                  c.motivo == MotivoCierreOferta.tomada
                      ? ResultadoRespuestaOferta.perdida
                      : ResultadoRespuestaOferta.expirada,
                ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Volver a la bandeja'),
        ),
      ],
    );
  }
}
