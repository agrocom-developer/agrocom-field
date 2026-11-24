import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/drones_repositorio.dart';
import 'drones_cubit.dart';

/// Los drones del proveedor: el «vehículo» del marketplace, con su estado,
/// su aprobación y los ciclos de batería.
class DronesPantalla extends StatelessWidget {
  const DronesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DronesCubit(context.read<DronesRepositorio>())..iniciar(),
      child: const DronesVista(),
    );
  }
}

/// La lista de drones sobre un [DronesCubit] ya provisto.
class DronesVista extends StatelessWidget {
  const DronesVista({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<DronesCubit, DronesEstado>(
      builder: (context, estado) {
        final subtitulo = switch (estado) {
          DronesListos(:final drones) when drones.isNotEmpty =>
            drones.length == 1
                ? '1 dron registrado'
                : '${drones.length} drones registrados',
          _ => null,
        };
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text('Mis drones', style: texto.headlineMedium),
            if (subtitulo != null) ...[
              const SizedBox(height: EspaciadoCampo.xs),
              Text(subtitulo, style: texto.bodyLarge),
            ],
            const SizedBox(height: EspaciadoCampo.l),
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
              child: switch (estado) {
                DronesCargando() => const Column(
                  key: ValueKey('cargando'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EsqueletoCampo(alto: 168, radio: 18),
                    SizedBox(height: EspaciadoCampo.m),
                    EsqueletoCampo(alto: 168, radio: 18),
                  ],
                ),
                DronesError() => EstadoErrorMarketplace(
                  key: const ValueKey('error'),
                  titulo: 'No pudimos cargar tus drones',
                  detalle: 'Revisá la conexión y volvé a intentar.',
                  onReintentar: context.read<DronesCubit>().iniciar,
                ),
                DronesListos(:final drones) when drones.isEmpty =>
                  const EstadoVacioMarketplace(
                    key: ValueKey('vacio'),
                    icono: Icons.flight_outlined,
                    titulo: 'Todavía no registraste drones',
                    detalle:
                        'Sin un dron aprobado no llegan ofertas. Cada dron lo '
                        'aprueba un administrador.',
                  ),
                DronesListos(:final drones) => Column(
                  key: const ValueKey('lista'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in drones) ...[
                      TarjetaDron(dron: d),
                      const SizedBox(height: EspaciadoCampo.m),
                    ],
                  ],
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// Un dron: modelo y matrícula, si está disponible, si está aprobado y
/// cuánta batería le queda de vida útil.
class TarjetaDron extends StatelessWidget {
  const TarjetaDron({required this.dron, super.key});

  final Dron dron;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final (tono, icono) = switch (dron.estado) {
      EstadoDron.disponible => (TonoEstado.exito, Icons.check_circle_rounded),
      EstadoDron.enServicio => (TonoEstado.info, Icons.flight_takeoff_rounded),
      EstadoDron.mantenimiento => (TonoEstado.alerta, Icons.build_rounded),
    };
    final (tonoAprobacion, iconoAprobacion) = switch (dron.aprobacion) {
      EstadoAprobacion.aprobado => (TonoEstado.exito, Icons.verified_rounded),
      EstadoAprobacion.pendiente => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
      ),
      EstadoAprobacion.suspendido => (
        TonoEstado.alerta,
        Icons.pause_circle_outline_rounded,
      ),
      EstadoAprobacion.rechazado => (TonoEstado.error, Icons.cancel_outlined),
    };
    final porcentaje = (dron.desgasteBateria * 100).round();
    final colorBateria = dron.bateriaPorAgotarse
        ? paleta.alerta
        : paleta.acentoTexto;
    return SuperficieMarketplace(
      key: ValueKey('dron-${dron.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dron.modelo, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            '${dron.matricula} · ${dron.propiedad.etiqueta} · '
            '${FormatoMarketplace.litros(dron.capacidadLitros)}',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspaciadoCampo.m),
          Wrap(
            spacing: EspaciadoCampo.s,
            runSpacing: EspaciadoCampo.s,
            children: [
              ChipEstadoMarketplace(
                etiqueta: dron.estado.etiqueta,
                tono: tono,
                icono: icono,
              ),
              // Aprobado es lo esperado: solo se dice cuando no lo está.
              if (!dron.aprobacion.habilitado)
                ChipEstadoMarketplace(
                  etiqueta: dron.aprobacion.etiqueta,
                  tono: tonoAprobacion,
                  icono: iconoAprobacion,
                ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.l),
          Semantics(
            container: true,
            label:
                'Batería: ${dron.ciclosBateria} de '
                '${dron.cicloMaximoBateria} ciclos, $porcentaje por ciento '
                'de la vida útil',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text('CICLOS DE BATERÍA', style: texto.labelSmall),
                    ),
                    const SizedBox(width: EspaciadoCampo.m),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${dron.ciclosBateria}',
                            style: texto.headlineSmall,
                          ),
                          TextSpan(
                            text: ' de ${dron.cicloMaximoBateria}',
                            style: texto.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.s),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: dron.desgasteBateria,
                    minHeight: 10,
                    backgroundColor: paleta.borde,
                    color: colorBateria,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.s),
                if (dron.bateriaPorAgotarse)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.battery_alert_rounded,
                        size: 20,
                        color: paleta.alerta,
                      ),
                      const SizedBox(width: EspaciadoCampo.s),
                      Expanded(
                        child: Text(
                          dron.ciclosRestantes == 0
                              ? 'La batería cumplió su vida útil. Hay que '
                                    'cambiarla.'
                              : 'Quedan ${dron.ciclosRestantes} ciclos. '
                                    'Planificá el recambio.',
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.texto,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Quedan ${dron.ciclosRestantes} ciclos de vida útil.',
                    style: texto.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
