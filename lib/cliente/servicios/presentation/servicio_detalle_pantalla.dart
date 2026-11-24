import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../calificar/presentation/hoja_calificar.dart';
import '../../comun/presentation/barra_avance.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/boton_secundario.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../comun/presentation/linea_tiempo_servicio.dart';
import '../../comun/presentation/tarjeta_proveedor.dart';
import '../../conformidad/domain/conformidad_repositorio.dart';
import '../../conformidad/presentation/acta_pantalla.dart';
import '../../problema/domain/problema_repositorio.dart';
import '../../problema/presentation/reportar_problema_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../domain/servicios_cliente_repositorio.dart';
import 'servicio_detalle_cubit.dart';

/// Detalle de un servicio: en qué está, quién lo hace, sus evidencias y la
/// única acción que corresponde a su estado (seguir en vivo, dar
/// conformidad o calificar).
class ServicioDetallePantalla extends StatelessWidget {
  const ServicioDetallePantalla({required this.servicioId, super.key});

  final String servicioId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServicioDetalleCubit(
        servicios: context.read<ServiciosClienteRepositorio>(),
        conformidad: context.read<ConformidadRepositorio>(),
        problemas: context.read<ProblemaRepositorio>(),
        calificaciones: context.read<CalificacionRepositorio>(),
        servicioId: servicioId,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Servicio')),
        body: BlocBuilder<ServicioDetalleCubit, ServicioDetalleEstado>(
          builder: (context, estado) => AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
            switchInCurve: MovimientoCampo.entrada,
            child: switch (estado.fase) {
              FaseDetalle.cargando => const _Cargando(key: ValueKey('carga')),
              FaseDetalle.error => EstadoFalla(
                key: const ValueKey('error'),
                sinConexion: estado.sinConexion,
                queNoCargo: 'el servicio',
                alReintentar: context.read<ServicioDetalleCubit>().reintentar,
              ),
              FaseDetalle.noEncontrado => const EstadoVacioMarketplace(
                key: ValueKey('no-encontrado'),
                icono: Icons.search_off_rounded,
                titulo: 'No encontramos este servicio',
                detalle: 'Volvé a «Mis servicios» y abrilo de nuevo.',
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

  final ServicioDetalleEstado estado;

  Future<void> _abrirActa(BuildContext context, Servicio servicio) async {
    final cubit = context.read<ServicioDetalleCubit>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ActaPantalla(servicio: servicio)),
    );
    await cubit.recargarAnexos();
  }

  Future<void> _calificar(BuildContext context, Servicio servicio) async {
    final cubit = context.read<ServicioDetalleCubit>();
    if (await mostrarHojaCalificar(context, servicio)) {
      await cubit.recargarAnexos();
    }
  }

  Future<void> _reportar(BuildContext context, Servicio servicio) async {
    final cubit = context.read<ServicioDetalleCubit>();
    final reportado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportarProblemaPantalla(servicio: servicio),
      ),
    );
    if (reportado ?? false) await cubit.recargarAnexos();
  }

  /// La acción principal que corresponde al estado, o nada.
  Widget? _accion(BuildContext context, Servicio s) {
    final acta = estado.acta;
    if (s.estado == EstadoServicio.enEjecucion) {
      return BotonPrincipal(
        texto: 'Seguir en vivo',
        icono: Icons.map_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SeguimientoPantalla(servicio: s),
          ),
        ),
      );
    }
    if (s.estado != EstadoServicio.completado) return null;
    if (acta != null && acta.pendiente) {
      return BotonPrincipal(
        texto: 'Revisar y dar conformidad',
        onPressed: () => _abrirActa(context, s),
      );
    }
    if (s.puntajeDelCliente == null && estado.problema == null) {
      return BotonPrincipal(
        texto: 'Calificar al proveedor',
        icono: Icons.star_rounded,
        onPressed: () => _calificar(context, s),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = estado.servicio!;
    final proveedor = s.proveedor;
    final acta = estado.acta;
    final evidencias = estado.expediente?.evidencias ?? const [];
    final problema = estado.problema;
    final accion = _accion(context, s);
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final enVuelo = s.estado == EstadoServicio.enEjecucion;
    // De un servicio terminado, la acción y la línea de tiempo dependen del
    // acta: hasta que llega se muestra su hueco, no una acción equivocada.
    final esperaActa =
        s.estado == EstadoServicio.completado &&
        estado.expediente == null &&
        !estado.anexosIncompletos;
    // Se reporta mientras el servicio está en marcha o espera la
    // conformidad; firmada el acta, el plazo ya cerró.
    final puedeReportar =
        problema == null &&
        proveedor != null &&
        (s.estado.activo || (acta?.pendiente ?? false));

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
                    child: InsigniaEstadoServicio(s.estado),
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Semantics(
                    header: true,
                    child: Text(s.lote.nombre, style: texto.headlineSmall),
                  ),
                  Text(
                    '${s.lote.zona} · ${s.lote.cultivo} · '
                    '${FormatoMarketplace.fechaLarga(s.fechaDeseada)}',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  if (enVuelo) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    Text(
                      '${FormatoMarketplace.hectareas(s.hectareasCubiertas)} '
                      'de ${FormatoMarketplace.hectareas(s.hectareasDeclaradas)}'
                      '${s.etaMinutos != null ? ' · faltan ${FormatoMarketplace.duracionMinutos(s.etaMinutos!)}' : ''}',
                      style: texto.titleMedium,
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    BarraAvance(
                      valor: s.progreso,
                      etiqueta:
                          '${FormatoMarketplace.hectareas(s.hectareasCubiertas)} '
                          'de ${FormatoMarketplace.hectareas(s.hectareasDeclaradas)}',
                    ),
                  ],
                  if (esperaActa) ...[
                    const SizedBox(height: EspaciadoCampo.xl),
                    const EsqueletoCampo(
                      alto: ObjetivoTactilCampo.guantes,
                      radio: EspaciadoCampo.m,
                    ),
                  ] else if (accion != null) ...[
                    const SizedBox(height: EspaciadoCampo.xl),
                    accion,
                  ],
                  if (estado.anexosIncompletos) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
                      mensaje: estado.sinConexion
                          ? 'Sin conexión. Faltan cargar las evidencias y el '
                                'acta.'
                          : 'No pudimos cargar las evidencias y el acta.',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BotonSecundario(
                        texto: 'Reintentar',
                        icono: Icons.refresh_rounded,
                        onPressed: context
                            .read<ServicioDetalleCubit>()
                            .reintentar,
                      ),
                    ),
                  ],
                  if (s.estado == EstadoServicio.cancelado) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    const AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.cancel_outlined,
                      mensaje:
                          'Este servicio se canceló. Podés pedir uno nuevo '
                          'desde «Solicitar».',
                    ),
                  ],
                  if (problema != null) ...[
                    const SizedBox(height: EspaciadoCampo.l),
                    _ProblemaReportado(problema),
                  ],
                  const TituloSeccion('Estado'),
                  if (esperaActa)
                    const EsqueletoCampo(alto: 200, radio: EspaciadoCampo.m)
                  else
                    LineaTiempoServicio(hitos: estado.hitos),
                  if (proveedor != null) ...[
                    const TituloSeccion('Quién fumiga'),
                    TarjetaProveedor(proveedor: proveedor, dron: s.dron),
                  ],
                  if (evidencias.isNotEmpty || acta != null) ...[
                    const TituloSeccion('Evidencias y acta'),
                    _ResumenExpediente(
                      acta: acta,
                      evidencias: evidencias.length,
                      alAbrir: () => _abrirActa(context, s),
                    ),
                  ],
                  const TituloSeccion('Aplicación'),
                  SuperficieMarketplace(
                    child: ListaDatos([
                      FilaDato(
                        'Superficie',
                        FormatoMarketplace.hectareas(s.hectareasDeclaradas),
                      ),
                      FilaDato('Producto', s.producto),
                      FilaDato(
                        'Dosis',
                        '${FormatoMarketplace.numero(s.dosisLitrosPorHectarea, decimales: 1)} L/ha',
                      ),
                      FilaDato(
                        'Caldo total',
                        FormatoMarketplace.litros(s.litrosTotales),
                      ),
                      FilaDato(
                        'Precio estimado',
                        FormatoMarketplace.bs(s.precio),
                      ),
                    ]),
                  ),
                  if (s.puntajeDelCliente != null ||
                      s.puntajeDelProveedor != null) ...[
                    const TituloSeccion('Calificaciones'),
                    SuperficieMarketplace(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s.puntajeDelCliente != null)
                            _Calificacion(
                              titulo: 'Tu calificación',
                              puntaje: s.puntajeDelCliente!,
                              emitida: estado.calificacion,
                            ),
                          if (s.puntajeDelCliente != null &&
                              s.puntajeDelProveedor != null)
                            Divider(
                              height: EspaciadoCampo.xl,
                              color: paleta.borde,
                            ),
                          if (s.puntajeDelProveedor != null)
                            _Calificacion(
                              titulo: 'Te calificó el proveedor',
                              puntaje: s.puntajeDelProveedor!,
                            ),
                        ],
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

class _ResumenExpediente extends StatelessWidget {
  const _ResumenExpediente({
    required this.acta,
    required this.evidencias,
    required this.alAbrir,
  });

  final ActaConformidad? acta;
  final int evidencias;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final acta = this.acta;
    final fotos = '$evidencias ${evidencias == 1 ? 'evidencia' : 'evidencias'}';
    return Semantics(
      button: true,
      child: SuperficieMarketplace(
        onTap: alAbrir,
        child: Row(
          children: [
            Icon(Icons.photo_library_outlined, color: paleta.acentoTexto),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acta == null ? fotos : 'Acta · ${acta.estado.etiqueta}',
                    style: texto.titleSmall,
                  ),
                  Text(
                    acta == null
                        ? 'El acta llega cuando el equipo termina.'
                        : '${FormatoMarketplace.hectareas(acta.hectareasConfirmadas)} '
                              'confirmadas · $fotos',
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: paleta.textoSecundario),
          ],
        ),
      ),
    );
  }
}

class _Calificacion extends StatelessWidget {
  const _Calificacion({
    required this.titulo,
    required this.puntaje,
    this.emitida,
  });

  final String titulo;
  final int puntaje;
  final CalificacionEmitida? emitida;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final etiquetas = emitida?.etiquetas ?? const <EtiquetaCalificacion>{};
    final comentario = emitida?.comentario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
        const SizedBox(height: EspaciadoCampo.xs),
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
