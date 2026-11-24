import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/estado_red.dart';
import '../domain/ofertas_repositorio.dart';
import 'oferta_detalle_pantalla.dart';
import 'ofertas_cubit.dart';
import 'ofertas_estado.dart';

/// Bandeja de ofertas del proveedor. Aceptar y rechazar exigen red: la
/// respuesta va directo a la API con una clave de idempotencia por oferta
/// (ADR 0009). Sin red la bandeja se sigue viendo y los botones lo dicen.
class OfertasPantalla extends StatelessWidget {
  const OfertasPantalla({this.reloj = DateTime.now, super.key});

  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OfertasCubit(
        repositorio: context.read<OfertasRepositorio>(),
        estadoRed: context.read<EstadoRed>(),
        reloj: reloj,
      )..iniciar(),
      child: const OfertasVista(),
    );
  }
}

/// Texto del aviso que sigue a una respuesta.
String mensajeDeRespuesta(ResultadoRespuestaOferta r) => switch (r) {
  ResultadoRespuestaOferta.aceptada =>
    'Servicio aceptado. Ya lo tenés en «Servicio».',
  ResultadoRespuestaOferta.perdida => 'Otro proveedor lo aceptó antes que vos.',
  ResultadoRespuestaOferta.expirada => 'La oferta venció.',
  ResultadoRespuestaOferta.rechazada => 'Oferta rechazada.',
  ResultadoRespuestaOferta.sinConexion =>
    'Sin conexión: aceptar y rechazar necesitan red.',
};

/// La bandeja sobre un [OfertasCubit] ya provisto.
class OfertasVista extends StatelessWidget {
  const OfertasVista({super.key});

  void _abrirDetalle(BuildContext context, Oferta oferta) {
    final cubit = context.read<OfertasCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: OfertaDetallePantalla(ofertaId: oferta.id),
        ),
      ),
    );
  }

  /// Alguna oferta acaba de entrar en sus últimos diez segundos.
  static bool _entraEnUrgencia(OfertasEstado antes, OfertasEstado ahora) {
    const umbral = Duration(seconds: 10);
    return ahora.ofertas.any(
      (o) =>
          o.restante(ahora.ahora) <= umbral && o.restante(antes.ahora) > umbral,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aviso háptico junto al anillo que pasa a rojo (sistema visual, §9).
    return BlocListener<OfertasCubit, OfertasEstado>(
      listenWhen: _entraEnUrgencia,
      listener: (_, _) => HapticaCampo.alerta(),
      child: _bandeja(context),
    );
  }

  Widget _bandeja(BuildContext context) {
    return BlocConsumer<OfertasCubit, OfertasEstado>(
      listenWhen: (a, b) => a.aviso?.numero != b.aviso?.numero,
      listener: (context, estado) {
        final aviso = estado.aviso;
        if (aviso == null) return;
        if (aviso.resultado == ResultadoRespuestaOferta.aceptada) {
          HapticaCampo.confirmacion();
        } else if (aviso.resultado == ResultadoRespuestaOferta.perdida) {
          HapticaCampo.alerta();
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(mensajeDeRespuesta(aviso.resultado))),
          );
      },
      builder: (context, estado) {
        final texto = Theme.of(context).textTheme;
        final paleta = context.paleta;
        final cubit = context.read<OfertasCubit>();
        final n = estado.ofertas.length;
        final vacia = n == 0 && estado.cerradas.isEmpty;
        final subtitulo = switch (estado.carga) {
          CargaOfertas.cargando => 'Buscando ofertas…',
          CargaOfertas.error => 'No pudimos cargar la bandeja.',
          CargaOfertas.lista when n == 0 =>
            'Te avisamos cuando haya una nueva.',
          CargaOfertas.lista =>
            '$n ${n == 1 ? 'oferta vigente' : 'ofertas vigentes'}',
        };

        final Widget cuerpo = switch (estado.carga) {
          CargaOfertas.cargando => const _Cargando(key: ValueKey('cargando')),
          CargaOfertas.error => EstadoErrorMarketplace(
            key: const ValueKey('error'),
            titulo: 'No pudimos cargar las ofertas',
            detalle: 'Revisá la conexión y volvé a intentar.',
            onReintentar: cubit.reintentar,
          ),
          CargaOfertas.lista when vacia => EstadoVacioMarketplace(
            key: const ValueKey('vacia'),
            icono: Icons.notifications_none_rounded,
            titulo: 'Sin ofertas por ahora',
            detalle: estado.enLinea
                ? 'Las ofertas llegan primero a la flota de Agrocom y luego '
                      'a proveedores de tu zona.'
                : 'La bandeja se actualiza cuando vuelva la conexión.',
          ),
          CargaOfertas.lista => Column(
            key: const ValueKey('lista'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final o in estado.ofertas) ...[
                if (o.esDeAgrocom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: paleta.acentoTexto,
                        ),
                        const SizedBox(width: EspaciadoCampo.s),
                        Expanded(
                          child: Text(
                            'Asignación prioritaria · flota de Agrocom',
                            style: texto.titleMedium?.copyWith(
                              color: paleta.acentoTexto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                OfertaServicioCampo(
                  key: ValueKey('oferta-${o.id}'),
                  titulo:
                      '${FormatoMarketplace.hectareas(o.lote.hectareas)} · '
                      '${o.lote.cultivo}',
                  detalle:
                      '${o.lote.nombre}, ${o.lote.zona}\n'
                      '${o.producto} · '
                      '${FormatoMarketplace.fechaCorta(o.fechaServicio)}',
                  distancia: FormatoMarketplace.kilometros(o.distanciaKm),
                  monto: FormatoMarketplace.bs(o.pago),
                  restante: o.restante(estado.ahora),
                  total: o.ventana,
                  mapa: MapaLote(
                    lotes: [o.lote],
                    seleccionado: o.lote,
                    interactivo: false,
                    relleno: const EdgeInsets.all(EspaciadoCampo.xl),
                  ),
                  respondiendo: estado.respondiendo.contains(o.id),
                  sinConexion: !estado.enLinea,
                  onAceptar: () => cubit.aceptar(o.id),
                  onRechazar: () => cubit.rechazar(o.id),
                  onDetalle: () => _abrirDetalle(context, o),
                ),
                const SizedBox(height: EspaciadoCampo.l),
              ],
              for (final c in estado.cerradas) ...[
                TarjetaOfertaCerrada(
                  cerrada: c,
                  onQuitar: () => cubit.descartar(c.oferta.id),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
            ],
          ),
        };

        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text('Ofertas', style: texto.headlineMedium),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(subtitulo, style: texto.bodyLarge),
            const SizedBox(height: EspaciadoCampo.l),
            if (!estado.enLinea) ...[
              const AvisoMarketplace(
                key: Key('bandeja-sin-conexion'),
                tono: TonoAviso.alerta,
                icono: Icons.wifi_off_rounded,
                mensaje:
                    'Sin conexión. Podés ver las ofertas, pero aceptar y '
                    'rechazar necesitan red. La cuenta regresiva sigue '
                    'corriendo.',
              ),
              const SizedBox(height: EspaciadoCampo.l),
            ],
            AnimatedSwitcher(
              duration: MovimientoCampo.duracion(
                context,
                MovimientoCampo.media,
              ),
              switchInCurve: MovimientoCampo.entrada,
              switchOutCurve: MovimientoCampo.salida,
              layoutBuilder: (actual, anteriores) => Stack(
                alignment: Alignment.topCenter,
                children: [...anteriores, ?actual],
              ),
              child: cuerpo,
            ),
            if (estado.carga == CargaOfertas.lista && estado.enLinea) ...[
              const SizedBox(height: EspaciadoCampo.s),
              const AvisoMarketplace(
                mensaje:
                    'Aceptar y rechazar necesitan conexión. Una vez aceptado, '
                    'el servicio se baja al dispositivo y se ejecuta sin red.',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EsqueletoCampo(alto: 420, radio: 28),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 120, radio: 28),
      ],
    );
  }
}

/// Oferta que ya no se puede tomar. Se cuenta sin alarma: no es un error
/// del proveedor, y llega otra.
class TarjetaOfertaCerrada extends StatelessWidget {
  const TarjetaOfertaCerrada({
    required this.cerrada,
    required this.onQuitar,
    super.key,
  });

  final OfertaCerrada cerrada;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final o = cerrada.oferta;
    final (icono, titulo, detalle) = switch (cerrada.motivo) {
      MotivoCierreOferta.tomada => (
        Icons.group_outlined,
        'Ya la tomó otro proveedor',
        'Aceptó antes. No afecta tu calificación.',
      ),
      MotivoCierreOferta.vencida => (
        Icons.timer_off_outlined,
        'Oferta vencida',
        'Se agotó el tiempo para responder.',
      ),
    };
    return SuperficieMarketplace(
      key: ValueKey('cerrada-${o.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: paleta.textoSecundario),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleLarge),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      '${FormatoMarketplace.hectareas(o.lote.hectareas)} · '
                      '${o.lote.nombre}, ${o.lote.zona}',
                      style: texto.bodyLarge,
                    ),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(detalle, style: texto.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: onQuitar,
                tooltip: 'Quitar',
                color: paleta.texto,
                constraints: const BoxConstraints(
                  minWidth: ObjetivoTactilCampo.guantes,
                  minHeight: ObjetivoTactilCampo.guantes,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
