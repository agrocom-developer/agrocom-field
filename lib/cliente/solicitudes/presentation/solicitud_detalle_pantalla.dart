import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../calificar/presentation/hoja_calificar.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/boton_secundario.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../comun/presentation/hoja_precio.dart';
import '../../comun/presentation/insignia_estado_solicitud.dart';
import '../../comun/presentation/linea_tiempo_solicitud.dart';
import '../../ofertas/presentation/ofertas_pantalla.dart';
import '../../problema/domain/problema_repositorio.dart';
import '../../problema/presentation/reportar_problema_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../domain/solicitud.dart';
import '../domain/solicitudes_repositorio.dart';
import 'solicitud_detalle_cubit.dart';

/// Detalle de una solicitud: en qué está, qué se pidió, el piloto elegido y
/// la única acción que corresponde a su estado (ver las ofertas, seguir el
/// trabajo, calificar o volver a abrirla).
class SolicitudDetallePantalla extends StatelessWidget {
  const SolicitudDetallePantalla({required this.solicitudId, super.key});

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
      child: Scaffold(
        appBar: AppBar(title: const Text('Solicitud')),
        body: BlocBuilder<SolicitudDetalleCubit, SolicitudDetalleEstado>(
          builder: (context, estado) => AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
            switchInCurve: MovimientoCampo.entrada,
            child: switch (estado.fase) {
              FaseDetalle.cargando => const _Cargando(key: ValueKey('carga')),
              FaseDetalle.error => EstadoFalla(
                key: const ValueKey('error'),
                sinConexion: estado.sinConexion,
                queNoCargo: 'la solicitud',
                alReintentar: context.read<SolicitudDetalleCubit>().reintentar,
              ),
              FaseDetalle.noEncontrado => const EstadoVacioMarketplace(
                key: ValueKey('no-encontrado'),
                icono: Icons.search_off_rounded,
                titulo: 'No encontramos esta solicitud',
                detalle: 'Vuelve a «Solicitudes» y ábrela de nuevo.',
              ),
              FaseDetalle.listo => _Contenido(
                key: const ValueKey('contenido'),
                estado: estado,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado, super.key});

  final SolicitudDetalleEstado estado;

  void _verOfertas(BuildContext context, Solicitud s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfertasPantalla(solicitudId: s.id),
      ),
    );
  }

  void _seguir(BuildContext context, Solicitud s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientoPantalla(solicitudId: s.id),
      ),
    );
  }

  Future<void> _calificar(BuildContext context, Solicitud s) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    if (await mostrarHojaCalificar(context, s)) {
      await cubit.recargarAnexos();
    }
  }

  Future<void> _reportar(BuildContext context, Solicitud s) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    final reportado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReportarProblemaPantalla(servicio: s)),
    );
    if (reportado ?? false) await cubit.recargarAnexos();
  }

  Future<void> _cambiarPrecio(BuildContext context, Solicitud s) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    final escrito = await mostrarHojaPrecio(
      context,
      titulo: 'Cambiar tu precio',
      textoAccion: 'Guardar precio',
      hectareas: s.hectareas,
      inicial: s.precioHaPropuesto,
      apoyo:
          'Las ofertas que ya recibiste no cambian; los pilotos que '
          'negocian contigo reciben el aviso.',
    );
    if (escrito != null) await cubit.cambiarPrecio(escrito.precio);
  }

  Future<void> _cancelar(BuildContext context) async {
    final cubit = context.read<SolicitudDetalleCubit>();
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoCancelar(),
    );
    if (motivo != null) await cubit.cancelar(motivo);
  }

  /// La acción principal que corresponde al estado, o nada.
  Widget? _accion(BuildContext context, Solicitud s) {
    final cubit = context.read<SolicitudDetalleCubit>();
    switch (s.estado) {
      case EstadoSolicitud.conOfertas:
        final n = s.ofertasVigentes ?? 0;
        return BotonPrincipal(
          key: const ValueKey('ver-ofertas'),
          texto: n > 0 ? 'Ver y comparar las ofertas ($n)' : 'Ver las ofertas',
          icono: Icons.local_offer_rounded,
          onPressed: () => _verOfertas(context, s),
        );
      case EstadoSolicitud.abierta:
        return BotonPrincipal(
          key: const ValueKey('ver-ofertas'),
          texto: 'Ver las ofertas',
          icono: Icons.local_offer_outlined,
          onPressed: () => _verOfertas(context, s),
        );
      case EstadoSolicitud.adjudicada || EstadoSolicitud.enEjecucion:
        return BotonPrincipal(
          key: const ValueKey('ver-seguimiento'),
          texto: 'Ver seguimiento y chat',
          icono: Icons.timeline_rounded,
          onPressed: () => _seguir(context, s),
        );
      case EstadoSolicitud.finalizada:
        if (s.puntajeDelCliente == null && estado.problema == null) {
          return BotonPrincipal(
            key: const ValueKey('calificar'),
            texto: 'Calificar al piloto',
            icono: Icons.star_rounded,
            onPressed: () => _calificar(context, s),
          );
        }
        return null;
      case EstadoSolicitud.expirada:
        return BotonPrincipal(
          key: const ValueKey('renovar'),
          texto: 'Volver a abrir la solicitud',
          icono: Icons.refresh_rounded,
          cargando: estado.enCurso,
          onPressed: cubit.renovar,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = estado.solicitud!;
    final accion = _accion(context, s);
    final problema = estado.problema;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final puedeReportar =
        problema == null &&
        (s.estado == EstadoSolicitud.finalizada ||
            s.estado == EstadoSolicitud.calificada);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.only(bottom: EspaciadoCampo.xxl),
          children: [
            SizedBox(
              height: 180,
              child: MapaLote(
                lotes: [s.lote],
                seleccionado: s.lote,
                interactivo: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(margen, EspaciadoCampo.l, margen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InsigniaEstadoSolicitud(
                      s.estado,
                      ofertas: s.ofertasVigentes,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Semantics(
                    header: true,
                    child: Text(s.lote.nombre, style: texto.headlineSmall),
                  ),
                  Text(
                    '${s.lote.zona} · ${s.cultivo} · '
                    '${FormatoMarketplace.fechaLarga(s.ventanaDesde)}',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Text(s.estado.apoyo, style: texto.bodyMedium),
                  if (estado.fallo != null) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    Semantics(
                      liveRegion: true,
                      child: AvisoMarketplace(
                        key: const ValueKey('aviso-accion'),
                        tono: TonoAviso.error,
                        icono: estado.fallo == FalloAccion.sinConexion
                            ? Icons.wifi_off_rounded
                            : null,
                        mensaje: estado.fallo == FalloAccion.sinConexion
                            ? 'Sin conexión. No se guardó el cambio; '
                                  'inténtalo con señal.'
                            : (estado.mensajeFallo ??
                                  'No pudimos completar la operación.'),
                      ),
                    ),
                  ],
                  if (s.estado.terminada) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    _PrecioFinal(solicitud: s),
                  ] else if (s.estado.negociando) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    _TuPrecio(
                      solicitud: s,
                      alCambiar: estado.enCurso
                          ? null
                          : () => _cambiarPrecio(context, s),
                    ),
                  ],
                  if (accion != null) ...[
                    const SizedBox(height: EspaciadoCampo.xl),
                    accion,
                  ],
                  if (estado.anexosIncompletos) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
                      mensaje: estado.sinConexion
                          ? 'Sin conexión. Faltan cargar tu calificación y el '
                                'reclamo.'
                          : 'No pudimos cargar tu calificación y el reclamo.',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BotonSecundario(
                        texto: 'Reintentar',
                        icono: Icons.refresh_rounded,
                        onPressed: context
                            .read<SolicitudDetalleCubit>()
                            .reintentar,
                      ),
                    ),
                  ],
                  if (s.estado == EstadoSolicitud.cancelada) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.cancel_outlined,
                      mensaje:
                          s.motivoCancelacion == null ||
                              s.motivoCancelacion!.isEmpty
                          ? 'Cancelaste esta solicitud. Puedes publicar otra '
                                'desde «Solicitar».'
                          : 'Cancelaste esta solicitud: '
                                '${s.motivoCancelacion}. Puedes publicar otra '
                                'desde «Solicitar».',
                    ),
                  ],
                  if (problema != null) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    _ProblemaReportado(problema),
                  ],
                  const TituloSeccion('Estado'),
                  LineaTiempoSolicitud(hitos: estado.hitos),
                  if (s.nombreProveedor != null && s.estado.conPiloto) ...[
                    const TituloSeccion('Quién fumiga'),
                    SuperficieMarketplace(
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, color: paleta.acentoTexto),
                          const SizedBox(width: EspaciadoCampo.m),
                          Expanded(
                            child: Text(
                              s.nombreProveedor!,
                              style: texto.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const TituloSeccion('Lo que pediste'),
                  SuperficieMarketplace(
                    child: ListaDatos([
                      FilaDato(
                        'Superficie',
                        FormatoMarketplace.hectareas(s.hectareas),
                      ),
                      FilaDato('Cultivo', s.cultivo),
                      FilaDato('Producto', s.producto),
                      FilaDato(
                        'Fecha deseada',
                        FormatoMarketplace.fechaConDia(s.ventanaDesde),
                      ),
                      if (s.accesos != null) FilaDato('Accesos', s.accesos!),
                      if (s.observaciones != null)
                        FilaDato('Observaciones', s.observaciones!),
                    ]),
                  ),
                  if (s.puntajeDelCliente != null) ...[
                    const TituloSeccion('Tu calificación'),
                    SuperficieMarketplace(
                      child: _Calificacion(
                        puntaje: s.puntajeDelCliente!,
                        emitida: estado.calificacion,
                      ),
                    ),
                  ],
                  if (s.estado.negociando) ...[
                    const SizedBox(height: EspaciadoCampo.xl),
                    Center(
                      child: BotonSecundario(
                        key: const ValueKey('cancelar-solicitud'),
                        texto: 'Cancelar la solicitud',
                        icono: Icons.close_rounded,
                        onPressed: estado.enCurso
                            ? null
                            : () => _cancelar(context),
                      ),
                    ),
                  ],
                  if (puedeReportar) ...[
                    const SizedBox(height: EspaciadoCampo.xl),
                    Center(
                      child: BotonSecundario(
                        texto: 'Reportar un problema',
                        icono: Icons.flag_outlined,
                        onPressed: () => _reportar(context, s),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El precio que propone el cliente mientras la solicitud se negocia, con la
/// opción de cambiarlo.
class _TuPrecio extends StatelessWidget {
  const _TuPrecio({required this.solicitud, required this.alCambiar});

  final Solicitud solicitud;
  final VoidCallback? alCambiar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = solicitud;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu precio propuesto',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${FormatoMarketplace.bs(s.precioHaPropuesto)}/ha',
              key: const ValueKey('precio-propuesto'),
              style: texto.headlineSmall,
            ),
          ),
          Text(
            'Total estimado ${FormatoMarketplace.bs(s.totalEstimado)} por '
            '${FormatoMarketplace.hectareas(s.hectareas)}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          BotonSecundario(
            key: const ValueKey('cambiar-precio'),
            texto: 'Cambiar mi precio',
            icono: Icons.edit_outlined,
            onPressed: alCambiar,
          ),
        ],
      ),
    );
  }
}

/// El precio final que calcula el servidor: hectáreas ejecutadas por precio
/// acordado. La app no cobra: el pago es fuera de ella.
class _PrecioFinal extends StatelessWidget {
  const _PrecioFinal({required this.solicitud});

  final Solicitud solicitud;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = solicitud;
    final ejecutadas = s.hectareasEjecutadas ?? s.hectareas;
    return SuperficieMarketplace(
      resaltada: s.estado == EstadoSolicitud.finalizada,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precio final a pagar',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FormatoMarketplace.bs(s.totalAPagar),
              key: const ValueKey('precio-final'),
              style: texto.displaySmall,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            '${FormatoMarketplace.hectareas(ejecutadas)} ejecutadas × '
            '${FormatoMarketplace.bs(s.precioHaVigente)}/ha',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            'Le pagas al piloto directamente, fuera de la app. Agrocom no '
            'cobra ni suma nada a este monto.',
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _Calificacion extends StatelessWidget {
  const _Calificacion({required this.puntaje, this.emitida});

  final int puntaje;
  final CalificacionEmitida? emitida;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final etiquetas = emitida?.etiquetas ?? const <EtiquetaCalificacion>{};
    final comentario = emitida?.comentario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalificacionCampo(valor: puntaje),
        if (etiquetas.isNotEmpty) ...[
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            [for (final e in etiquetas) e.etiqueta].join(' · '),
            style: texto.bodyMedium,
          ),
        ],
        if (comentario != null) ...[
          const SizedBox(height: EspaciadoCampo.xs),
          Text('«$comentario»', style: texto.bodyMedium),
        ],
      ],
    );
  }
}

class _ProblemaReportado extends StatelessWidget {
  const _ProblemaReportado(this.problema);

  final ProblemaReportado problema;

  @override
  Widget build(BuildContext context) => AvisoMarketplace(
    tono: TonoAviso.alerta,
    icono: Icons.flag_rounded,
    mensaje:
        'Reportaste un problema: ${problema.motivo.etiqueta}. Caso '
        '${problema.numeroCaso}, ${problema.estado.etiqueta.toLowerCase()}. '
        'Soporte te responde en 24 horas hábiles.',
  );
}

/// Pide el motivo de la cancelación. Es obligatorio: el servidor lo exige.
class _DialogoCancelar extends StatefulWidget {
  const _DialogoCancelar();

  @override
  State<_DialogoCancelar> createState() => _DialogoCancelarState();
}

class _DialogoCancelarState extends State<_DialogoCancelar> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valido = _motivo.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('¿Cancelar la solicitud?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Es gratis. Los pilotos con ofertas verán que se cerró.'),
          const SizedBox(height: EspaciadoCampo.m),
          TextField(
            key: const ValueKey('motivo-cancelacion'),
            controller: _motivo,
            autofocus: true,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          key: const ValueKey('confirmar-cancelar'),
          onPressed: valido
              ? () => Navigator.of(context).pop(_motivo.text.trim())
              : null,
          child: const Text('Cancelar solicitud'),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: 180, radio: 0),
        Padding(
          padding: EdgeInsets.all(EspaciadoCampo.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EsqueletoCampo(alto: EspaciadoCampo.xl, ancho: 140),
              SizedBox(height: EspaciadoCampo.m),
              EsqueletoCampo(alto: EspaciadoCampo.xxl, ancho: 220),
              SizedBox(height: EspaciadoCampo.xl),
              EsqueletoCampo(alto: ObjetivoTactilCampo.guantes, radio: 14),
              SizedBox(height: EspaciadoCampo.xl),
              EsqueletoCampo(alto: 160, radio: 18),
            ],
          ),
        ),
      ],
    ),
  );
}
