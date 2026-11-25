import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../calificar/presentation/calificar_pantalla.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../problema/domain/problema_repositorio.dart';
import '../../problema/presentation/reportar_problema_pantalla.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../../solicitudes/presentation/solicitud_detalle_cubit.dart';

/// Precio final del servicio como un ticket: hectáreas ejecutadas por el
/// precio acordado y el total, que el servidor congela al terminar (la app no
/// recalcula montos). El pago es directo al piloto, fuera de la app: aquí no
/// se cobra nada.
///
/// Las acciones son las que el contrato ofrece al cliente: calificar al
/// piloto y reportar un problema. No hay un paso de «confirmar» el precio.
class PrecioFinalPantalla extends StatelessWidget {
  const PrecioFinalPantalla({required this.solicitudId, super.key});

  final String solicitudId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SolicitudDetalleCubit(
        solicitudes: context.read<SolicitudesRepositorio>(),
        problemas: context.read<ProblemaRepositorio>(),
        calificaciones: context.read<CalificacionRepositorio>(),
        solicitudId: solicitudId,
      ),
      child: BlocBuilder<SolicitudDetalleCubit, SolicitudDetalleEstado>(
        builder: (context, estado) {
          final s = estado.solicitud;
          return Scaffold(
            appBar: AppBar(
              title: _Titulo(
                apoyo: s == null
                    ? null
                    : '${s.lote.nombre} · servicio terminado',
              ),
            ),
            body: AnimatedSwitcher(
              duration: MovimientoCampo.duracion(
                context,
                MovimientoCampo.media,
              ),
              switchInCurve: MovimientoCampo.entrada,
              child: switch (estado.fase) {
                FaseDetalle.cargando => const _Cargando(key: ValueKey('carga')),
                FaseDetalle.error => EstadoFalla(
                  key: const ValueKey('error'),
                  sinConexion: estado.sinConexion,
                  queNoCargo: 'el precio final',
                  alReintentar: context
                      .read<SolicitudDetalleCubit>()
                      .reintentar,
                ),
                FaseDetalle.noEncontrado => const EstadoVacioMarketplace(
                  key: ValueKey('no-encontrado'),
                  icono: Icons.search_off_rounded,
                  titulo: 'No encontramos este servicio',
                  detalle: 'Vuelve a «Solicitudes» y ábrelo de nuevo.',
                ),
                FaseDetalle.listo => _Contenido(
                  key: const ValueKey('contenido'),
                  estado: estado,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({this.apoyo});

  final String? apoyo;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (apoyo != null)
          Text(
            apoyo!,
            style: TipografiaCampo.cuerpoSecundario.copyWith(
              color: paleta.textoSecundario,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          'Precio final',
          style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado, super.key});

  final SolicitudDetalleEstado estado;

  Future<void> _calificar(BuildContext context, Solicitud s) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    if (await abrirCalificar(context, s)) await cubit.recargarAnexos();
  }

  Future<void> _reportar(BuildContext context, Solicitud s) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    final reportado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReportarProblemaPantalla(servicio: s)),
    );
    if (reportado ?? false) await cubit.recargarAnexos();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final s = estado.solicitud!;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final ejecutadas = s.hectareasEjecutadas ?? s.hectareas;
    final menos = s.hectareas - ejecutadas;
    final puedeCalificar =
        s.estado == EstadoSolicitud.finalizada &&
        s.puntajeDelCliente == null &&
        estado.problema == null;
    final puedeReportar =
        estado.problema == null &&
        (s.estado == EstadoSolicitud.finalizada ||
            s.estado == EstadoSolicitud.calificada);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margen,
                  EspaciadoCampo.l,
                  margen,
                  EspaciadoCampo.xl,
                ),
                children: [
                  TicketPedidoCampo(
                    numero: 'PEDIDO #${s.id}',
                    estado: s.estado.etiqueta,
                    filas: [
                      FilaTicketCampo(
                        clave: 'Hectáreas ejecutadas',
                        valor: FormatoMarketplace.hectareasNumero(ejecutadas),
                        unidad: 'ha',
                        esCifra: true,
                      ),
                      FilaTicketCampo(
                        clave: 'Precio acordado',
                        valor:
                            '× ${FormatoMarketplace.bsNumero(s.precioHaVigente)}',
                        unidad: 'Bs/ha',
                        esCifra: true,
                      ),
                    ],
                    etiquetaTotal: 'Total a pagar al piloto',
                    total: FormatoMarketplace.bsNumero(s.totalAPagar),
                  ),
                  if (menos > Decimal.zero) ...[
                    const SizedBox(height: EspaciadoCampo.m),
                    AvisoMarketplace(
                      key: const ValueKey('aviso-diferencia'),
                      tono: TonoAviso.alerta,
                      icono: Icons.straighten_rounded,
                      mensaje:
                          'Son ${FormatoMarketplace.hectareas(menos)} menos '
                          'que las publicadas '
                          '(${FormatoMarketplace.hectareas(s.hectareas)}). '
                          'El total sale de lo que el piloto ejecutó.',
                    ),
                  ],
                  const SizedBox(height: EspaciadoCampo.m),
                  const AvisoMarketplace(
                    key: ValueKey('aviso-pago-directo'),
                    icono: Icons.handshake_outlined,
                    mensaje:
                        'El pago es directo al piloto. Agrocom no cobra '
                        'dentro de la app.',
                  ),
                  if (estado.problema != null) ...[
                    const SizedBox(height: EspaciadoCampo.m),
                    AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.flag_rounded,
                      mensaje:
                          'Reportaste un problema (caso '
                          '${estado.problema!.numeroCaso}). Soporte te '
                          'responde en 24 horas hábiles.',
                    ),
                  ],
                  if (s.puntajeDelCliente != null) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    Row(
                      children: [
                        Text(
                          'Tu calificación',
                          style: TipografiaCampo.cuerpoSecundario.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                        const SizedBox(width: EspaciadoCampo.m),
                        CalificacionCampo(valor: s.puntajeDelCliente!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (puedeCalificar || puedeReportar)
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margen,
                EspaciadoCampo.s,
                margen,
                EspaciadoCampo.s,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (puedeCalificar)
                        BotonPrincipal(
                          key: const ValueKey('calificar-desde-precio'),
                          texto: 'Calificar al piloto',
                          icono: Icons.star_rounded,
                          onPressed: () => _calificar(context, s),
                        ),
                      if (puedeReportar)
                        TextButton(
                          key: const ValueKey('reportar-desde-precio'),
                          onPressed: () => _reportar(context, s),
                          style: TextButton.styleFrom(
                            foregroundColor: paleta.error,
                            minimumSize: const Size(
                              64,
                              ObjetivoTactilCampo.guantes,
                            ),
                          ),
                          child: const Text('Reportar un problema'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(EspaciadoCampo.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EsqueletoCampo(alto: 260, radio: RadioCampo.tarjeta),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: 64, radio: RadioCampo.media),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: 64, radio: RadioCampo.media),
      ],
    ),
  );
}
