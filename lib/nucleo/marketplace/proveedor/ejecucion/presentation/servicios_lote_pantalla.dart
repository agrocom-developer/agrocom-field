import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../di/dependencias_ejecucion.dart';
import '../domain/ejecucion.dart';
import 'ejecucion_cubits.dart';
import 'servicio_lote_pantalla.dart';

/// La pestaña «Servicio»: los servicios adjudicados del equipo, que se ven y
/// se operan sin red. Lee de la base local.
class ServiciosLotePantalla extends StatelessWidget {
  const ServiciosLotePantalla({this.alIrAlMapa, super.key});

  /// Salida de la lista vacía: «Ver lotes en el mapa».
  final VoidCallback? alIrAlMapa;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ServiciosLoteCubit(context.read<DependenciasEjecucion>().repositorio)
            ..iniciar(),
      child: ServiciosLoteVista(alIrAlMapa: alIrAlMapa),
    );
  }
}

class ServiciosLoteVista extends StatelessWidget {
  const ServiciosLoteVista({this.alIrAlMapa, super.key});

  final VoidCallback? alIrAlMapa;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<ServiciosLoteCubit, ServiciosLoteEstado>(
      builder: (context, estado) {
        final cubit = context.read<ServiciosLoteCubit>();
        return RefreshIndicator(
          onRefresh: cubit.actualizar,
          child: ListView(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            children: [
              Text(
                l10n.proveedorEjecucionServicio,
                style: texto.headlineMedium,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              switch (estado) {
                ServiciosLoteCargando() => const Column(
                  children: [
                    EsqueletoCampo(alto: 150, radio: 18),
                    SizedBox(height: EspaciadoCampo.m),
                    EsqueletoCampo(alto: 150, radio: 18),
                  ],
                ),
                ServiciosLoteError() => EstadoErrorMarketplace(
                  titulo: l10n.proveedorEjecucionPudimosLeerTusServicios,
                  detalle: l10n.proveedorEjecucionCierraAbreAppQue,
                  onReintentar: cubit.iniciar,
                ),
                ServiciosLoteListos(:final servicios) when servicios.isEmpty =>
                  EstadoVacioMarketplace(
                    etiquetaAccion: alIrAlMapa == null
                        ? null
                        : AppLocalizations.of(context).listaVerLotesMapa,
                    alAccion: alIrAlMapa,
                    icono: Icons.flight_takeoff_outlined,
                    titulo:
                        l10n.proveedorEjecucionTodaviaTienesServicioAdjudicado,
                    detalle: l10n.proveedorEjecucionCuandoClienteElijaServicio,
                  ),
                ServiciosLoteListos(:final servicios) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in servicios) ...[
                      TarjetaServicioLote(servicio: s),
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

/// Tono, ícono y texto de un estado del servicio.
(TonoEstado, IconData) estiloEstado(EstadoServicioLote e) => switch (e) {
  EstadoServicioLote.adjudicada => (
    TonoEstado.info,
    Icons.assignment_turned_in_rounded,
  ),
  EstadoServicioLote.enEjecucion => (
    TonoEstado.alerta,
    Icons.flight_takeoff_rounded,
  ),
  EstadoServicioLote.finalizada => (
    TonoEstado.exito,
    Icons.check_circle_rounded,
  ),
};

class TarjetaServicioLote extends StatelessWidget {
  const TarjetaServicioLote({required this.servicio, super.key});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final (tono, icono) = estiloEstado(s.estado);
    return Semantics(
      button: true,
      label: l10n.proveedorEjecucionServicioSemantica(
        FormatoMarketplace.hectareas(s.hectareas),
        s.cultivo == null ? '' : l10n.proveedorEjecucionDeCultivo(s.cultivo!),
        s.estado.etiqueta,
        s.pendientes > 0
            ? l10n.proveedorEjecucionPendientesSufijo(s.pendientes)
            : '',
      ),
      excludeSemantics: true,
      child: SuperficieMarketplace(
        resaltada: s.estado == EstadoServicioLote.enEjecucion,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ServicioLotePantalla(servicioId: s.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${FormatoMarketplace.hectareas(s.hectareas)}'
              '${s.cultivo == null ? '' : ' · ${s.cultivo}'}',
              style: texto.titleLarge,
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            ChipEstadoMarketplace(
              etiqueta: s.estado.etiqueta,
              tono: tono,
              icono: icono,
            ),
            if (s.terreno != null)
              Text(
                s.terreno!.nombre,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            const SizedBox(height: EspaciadoCampo.s),
            if (s.estado == EstadoServicioLote.enEjecucion) ...[
              BarraProgresoCampo(fraccion: s.progreso),
              const SizedBox(height: EspaciadoCampo.xs),
              Text(
                s.hectareasEjecutadas == null
                    ? l10n.proveedorEjecucionSinAvanceMarcado
                    : l10n.proveedorEjecucionDeTotal(
                        FormatoMarketplace.hectareas(s.hectareasEjecutadas!),
                        FormatoMarketplace.hectareas(s.hectareas),
                      ),
                style: texto.bodyMedium,
              ),
            ] else if (s.estado == EstadoServicioLote.finalizada &&
                s.montoAPagar != null)
              Text(
                '${s.montoConfirmado ? 'Precio final' : 'Precio estimado'} '
                '${FormatoMarketplace.bs(s.montoAPagar!)}',
                style: texto.titleMedium,
              )
            else
              Text(s.estado.apoyo, style: texto.bodyMedium),
            if (s.pendientes > 0 || s.rechazos > 0) ...[
              const SizedBox(height: EspaciadoCampo.s),
              ChipPendientes(servicio: s),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lo que falta subir o lo que el servidor rechazó, con texto e ícono (no
/// solo color).
class ChipPendientes extends StatelessWidget {
  const ChipPendientes({required this.servicio, super.key});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    if (s.rechazos > 0) {
      return ChipEstadoMarketplace(
        etiqueta: s.rechazos == 1
            ? l10n.proveedorEjecucionRegistroRechazado
            : l10n.proveedorEjecucionRegistrosRechazados(s.rechazos),
        tono: TonoEstado.error,
        icono: Icons.error_outline_rounded,
      );
    }
    return ChipEstadoMarketplace(
      etiqueta: s.pendientes == 1
          ? l10n.proveedorEjecucionCosaPorSubir
          : l10n.proveedorEjecucionCosasPorSubir(s.pendientes),
      tono: TonoEstado.info,
      icono: Icons.cloud_upload_outlined,
    );
  }
}
