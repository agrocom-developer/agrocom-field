import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/hoja_calificar.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/boton_secundario.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../problema/presentation/reportar_problema_pantalla.dart';
import '../domain/conformidad_repositorio.dart';
import 'acta_cubit.dart';
import 'galeria_evidencias.dart';

/// Evidencias y acta de conformidad de un servicio. Si el acta espera la
/// firma, la acción principal es dar la conformidad; reportar un problema es
/// la salida secundaria.
class ActaPantalla extends StatelessWidget {
  const ActaPantalla({required this.servicio, super.key});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActaCubit(
        context.read<ConformidadRepositorio>(),
        servicioId: servicio.id,
        claveIdempotencia: const Uuid().v4(),
      ),
      child: _Vista(servicio: servicio),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.servicio});

  final Servicio servicio;

  Future<void> _confirmar(BuildContext context) async {
    final cubit = context.read<ActaCubit>();
    final acepta = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.paleta.superficieElevada,
      builder: (_) => _HojaConfirmar(servicio: servicio),
    );
    if (acepta ?? false) await cubit.firmar();
  }

  Future<void> _reportar(BuildContext context) async {
    final cubit = context.read<ActaCubit>();
    final reportado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportarProblemaPantalla(servicio: servicio),
      ),
    );
    if (reportado ?? false) await cubit.cargar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActaCubit, ActaEstado>(
      listenWhen: (a, b) => a.fase != b.fase,
      listener: (context, estado) {
        if (estado.fase == FaseActa.firmada) HapticaCampo.confirmacion();
      },
      builder: (context, estado) {
        final acta = estado.acta;
        final firmando = estado.fase == FaseActa.firmando;
        final pideFirma = (acta?.pendiente ?? false) || firmando;
        final recienFirmada = estado.fase == FaseActa.firmada;
        return Scaffold(
          appBar: AppBar(title: const Text('Evidencias y acta')),
          body: AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
            switchInCurve: MovimientoCampo.entrada,
            child: switch (estado.fase) {
              FaseActa.cargando => const _Cargando(key: ValueKey('cargando')),
              FaseActa.error => EstadoFalla(
                key: const ValueKey('error'),
                sinConexion: estado.sinConexion,
                queNoCargo: 'las evidencias y el acta',
                alReintentar: context.read<ActaCubit>().cargar,
              ),
              _ => _Contenido(
                key: const ValueKey('contenido'),
                servicio: servicio,
                estado: estado,
              ),
            },
          ),
          bottomNavigationBar: !pideFirma && !recienFirmada
              ? null
              : _Pie(
                  children: recienFirmada
                      ? [
                          if (servicio.puntajeDelCliente == null)
                            BotonPrincipal(
                              texto: 'Calificar al proveedor',
                              icono: Icons.star_rounded,
                              onPressed: () async {
                                final navegador = Navigator.of(context);
                                final califico = await mostrarHojaCalificar(
                                  context,
                                  servicio,
                                );
                                if (califico) navegador.pop(true);
                              },
                            )
                          else
                            BotonPrincipal(
                              texto: 'Listo',
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                        ]
                      : [
                          BotonPrincipal(
                            key: const ValueKey('dar-conformidad'),
                            texto: 'Dar conformidad',
                            cargando: firmando,
                            onPressed: estado.puedeFirmar
                                ? () => _confirmar(context)
                                : null,
                          ),
                          const SizedBox(height: EspaciadoCampo.xs),
                          BotonSecundario(
                            texto: 'Reportar un problema',
                            onPressed: firmando
                                ? null
                                : () => _reportar(context),
                          ),
                        ],
                ),
        );
      },
    );
  }
}

/// Zona de acciones anclada abajo, sobre el área segura.
class _Pie extends StatelessWidget {
  const _Pie({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(top: BorderSide(color: paleta.borde)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          EspaciadoCampo.m,
          EspaciadoCampo.l,
          EspaciadoCampo.m,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.servicio, required this.estado, super.key});

  final Servicio servicio;
  final ActaEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final acta = estado.acta;
    final evidencias = estado.evidencias;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            margen,
            EspaciadoCampo.l,
            margen,
            EspaciadoCampo.xxl,
          ),
          children: [
            if (estado.fase == FaseActa.firmada) ...[
              Semantics(
                liveRegion: true,
                child: const AvisoMarketplace(
                  icono: Icons.verified_rounded,
                  mensaje:
                      'Conformidad registrada. Gracias por confirmar el '
                      'trabajo.',
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
            ],
            if (estado.mensajeError != null) ...[
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  tono: TonoAviso.error,
                  icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
                  mensaje: estado.mensajeError!,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
            ],
            Text(
              '${servicio.lote.nombre} · ${servicio.lote.zona}',
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            if (acta == null)
              Text('Evidencias del servicio', style: texto.headlineSmall)
            else ...[
              Text(
                '${FormatoMarketplace.hectareas(acta.hectareasConfirmadas)} '
                'confirmadas',
                style: texto.headlineSmall,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              _EstadoActaInsignia(acta.estado),
            ],
            if (acta == null) ...[
              const SizedBox(height: EspaciadoCampo.l),
              const AvisoMarketplace(
                mensaje:
                    'El acta va a estar lista cuando el equipo termine y '
                    'envíe el registro del vuelo.',
              ),
            ] else ...[
              const SizedBox(height: EspaciadoCampo.l),
              SuperficieMarketplace(
                child: ListaDatos([
                  FilaDato(
                    'Solicitadas',
                    FormatoMarketplace.hectareas(servicio.hectareasDeclaradas),
                  ),
                  FilaDato(
                    'Caldo aplicado',
                    FormatoMarketplace.litros(acta.litrosAplicados),
                  ),
                  FilaDato(
                    'Aplicación',
                    '${FormatoMarketplace.fechaLarga(acta.inicio)}, '
                        '${FormatoMarketplace.hora(acta.inicio)} a '
                        '${FormatoMarketplace.hora(acta.fin)}',
                  ),
                  if (acta.condiciones != null) ...[
                    FilaDato('Viento', '${acta.condiciones!.vientoKmH} km/h'),
                    FilaDato(
                      'Temperatura',
                      '${acta.condiciones!.temperaturaC} °C',
                    ),
                    FilaDato(
                      'Humedad',
                      '${acta.condiciones!.humedadPorcentaje} %',
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              Text(
                acta.resumen,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              if (acta.pendiente) ...[
                const SizedBox(height: EspaciadoCampo.m),
                Text(
                  'Si no respondés antes del '
                  '${FormatoMarketplace.fechaCorta(acta.venceConformidad)} a '
                  'las ${FormatoMarketplace.hora(acta.venceConformidad)}, el '
                  'servicio se da por conforme.',
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ],
            const TituloSeccion('Evidencias'),
            if (evidencias.isEmpty)
              const EstadoVacioMarketplace(
                icono: Icons.photo_library_outlined,
                titulo: 'Todavía no hay evidencias',
                detalle:
                    'Las fotos aparecen acá cuando el equipo las envía '
                    'desde el lote.',
              )
            else
              GaleriaEvidencias(evidencias: evidencias),
          ],
        ),
      ),
    );
  }
}

class _EstadoActaInsignia extends StatelessWidget {
  const _EstadoActaInsignia(this.estado);

  final EstadoActa estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final (color, icono) = switch (estado) {
      EstadoActa.pendiente => (paleta.alerta, Icons.draw_rounded),
      EstadoActa.firmada => (paleta.exito, Icons.verified_rounded),
      EstadoActa.observada => (paleta.error, Icons.report_rounded),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(EspaciadoCampo.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: EspaciadoCampo.l, color: color),
            const SizedBox(width: EspaciadoCampo.s),
            Flexible(
              child: Text(
                estado.etiqueta,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HojaConfirmar extends StatelessWidget {
  const _HojaConfirmar({required this.servicio});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.xl,
        0,
        EspaciadoCampo.xl,
        EspaciadoCampo.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('¿Dar conformidad?', style: texto.titleLarge),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            'Confirmás que el trabajo en ${servicio.lote.nombre} quedó bien '
            'hecho. Después de confirmar no se puede deshacer.',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrincipal(
            key: const ValueKey('confirmar-conformidad'),
            texto: 'Sí, dar conformidad',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          BotonSecundario(
            texto: 'Volver a revisar',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: EspaciadoCampo.l, ancho: 180),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: EspaciadoCampo.xxl, ancho: 240),
        SizedBox(height: EspaciadoCampo.xl),
        EsqueletoCampo(alto: 160),
        SizedBox(height: EspaciadoCampo.xl),
        Row(
          children: [
            Expanded(child: EsqueletoCampo(alto: 120)),
            SizedBox(width: EspaciadoCampo.m),
            Expanded(child: EsqueletoCampo(alto: 120)),
          ],
        ),
      ],
    ),
  );
}
