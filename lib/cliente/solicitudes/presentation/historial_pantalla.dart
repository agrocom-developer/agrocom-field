import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/estado_falla.dart';
import '../domain/solicitudes_repositorio.dart';
import 'historial_cubit.dart';
import 'solicitud_detalle_pantalla.dart';
import 'tarjeta_solicitud.dart';

/// Todos los servicios del cliente: cuánto lleva fumigado, un filtro simple
/// y la lista.
class HistorialPantalla extends StatelessWidget {
  const HistorialPantalla({
    this.reloj = DateTime.now,
    this.alPublicar,
    super.key,
  });

  /// Abre «Publicar lote»: la salida de la lista vacía.
  final VoidCallback? alPublicar;

  /// Fija el mes final del gráfico; las pruebas lo reemplazan.
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HistorialCubit(context.read<SolicitudesRepositorio>()),
      child: _Vista(reloj: reloj, alPublicar: alPublicar),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.reloj, this.alPublicar});

  final DateTime Function() reloj;
  final VoidCallback? alPublicar;

  @override
  Widget build(BuildContext context) {
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return BlocBuilder<HistorialCubit, HistorialEstado>(
      builder: (context, estado) {
        final cubit = context.read<HistorialCubit>();
        if (estado.fase == FaseHistorial.error) {
          return EstadoFalla(
            sinConexion: estado.sinConexion,
            queNoCargo: 'tus solicitudes',
            alReintentar: cubit.reintentar,
          );
        }
        final cargando = estado.fase == FaseHistorial.cargando;
        final visibles = estado.visibles;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                margen,
                EspaciadoCampo.xl,
                margen,
                EspaciadoCampo.xxl,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Mis solicitudes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                if (cargando)
                  const _Cargando()
                else ...[
                  if (estado.sinConexion) ...[
                    const AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.wifi_off_rounded,
                      mensaje:
                          'Sin conexión. Ves lo último que cargamos; puede '
                          'estar desactualizado.',
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                  ],
                  if (estado.totalCompletados > 0) ...[
                    _Resumen(estado: estado, hasta: reloj()),
                    const SizedBox(height: EspaciadoCampo.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<FiltroHistorial>(
                      showSelectedIcon: false,
                      // Con el texto ampliado los segmentos se apilan para
                      // que ninguna palabra se corte.
                      direction: MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? Axis.vertical
                          : Axis.horizontal,
                      segments: const [
                        ButtonSegment(
                          value: FiltroHistorial.todos,
                          label: Text('Todos'),
                        ),
                        ButtonSegment(
                          value: FiltroHistorial.activos,
                          label: Text('Activos'),
                        ),
                        ButtonSegment(
                          value: FiltroHistorial.completados,
                          label: Text('Listos'),
                        ),
                      ],
                      selected: {estado.filtro},
                      onSelectionChanged: (v) {
                        HapticaCampo.seleccion();
                        cubit.filtrar(v.first);
                      },
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  if (visibles.isEmpty)
                    EstadoVacioMarketplace(
                      icono: Icons.inbox_outlined,
                      titulo: switch (estado.filtro) {
                        FiltroHistorial.todos =>
                          'Todavía no publicaste solicitudes',
                        FiltroHistorial.activos =>
                          'No hay solicitudes en curso',
                        FiltroHistorial.completados =>
                          'Todavía no hay servicios terminados',
                      },
                      detalle: switch (estado.filtro) {
                        FiltroHistorial.completados =>
                          'Cuando un piloto termina, queda guardado acá con '
                              'sus fotos y el precio final.',
                        _ =>
                          'Publica un lote, compara las ofertas de los '
                              'pilotos y elige.',
                      },
                      etiquetaAccion:
                          estado.filtro == FiltroHistorial.completados ||
                              alPublicar == null
                          ? null
                          : AppLocalizations.of(context).publicarLote,
                      alAccion: estado.filtro == FiltroHistorial.completados
                          ? null
                          : alPublicar,
                    )
                  else
                    for (final s in visibles) ...[
                      TarjetaSolicitud(
                        key: ValueKey('solicitud-${s.id}'),
                        solicitud: s,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SolicitudDetallePantalla(solicitudId: s.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                    ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cuánto lleva fumigado el cliente y cómo se repartió en los últimos meses.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.estado, required this.hasta});

  final HistorialEstado estado;
  final DateTime hasta;

  static const _meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final meses = estado.hectareasPorMes(hasta: hasta);
    // La proporción exacta se convierte a `double` solo para dibujar.
    final altos = [for (final m in meses) m.hectareas.toDouble()];
    final maximo = altos.fold<double>(0, (a, b) => a > b ? a : b);
    final total = FormatoMarketplace.hectareas(estado.hectareasFumigadas);
    final servicios = estado.totalCompletados;
    final estiloEje = texto.labelSmall?.copyWith(color: paleta.textoSecundario);
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fumigado con Agrocom',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          Text(
            total,
            style: texto.headlineMedium?.copyWith(color: paleta.acentoTexto),
          ),
          Text(
            'en $servicios ${servicios == 1 ? 'servicio' : 'servicios'}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          if (maximo > 0) ...[
            const SizedBox(height: EspaciadoCampo.l),
            SizedBox(
              height: 120,
              child: Semantics(
                label:
                    'Hectáreas fumigadas por mes: '
                    '${[for (final m in meses) '${_meses[m.mes.month - 1]} ${FormatoMarketplace.hectareas(m.hectareas)}'].join(', ')}',
                child: ExcludeSemantics(
                  child: BarChart(
                    duration: MovimientoCampo.duracion(
                      context,
                      MovimientoCampo.media,
                    ),
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maximo * 1.25,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: EspaciadoCampo.xl,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(
                                top: EspaciadoCampo.xs,
                              ),
                              child: Text(
                                _meses[meses[v.toInt()].mes.month - 1],
                                // El eje es decorativo: el dato va en la
                                // etiqueta accesible y en el total.
                                textScaler: TextScaler.noScaling,
                                style: estiloEje,
                              ),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < altos.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: altos[i],
                                width: EspaciadoCampo.xl,
                                color: i == altos.length - 1
                                    ? paleta.acentoTexto
                                    : paleta.apoyo,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(EspaciadoCampo.xs),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EsqueletoCampo(alto: 180, radio: 18),
      SizedBox(height: EspaciadoCampo.xl),
      EsqueletoCampo(alto: ObjetivoTactilCampo.minimo, radio: 24),
      SizedBox(height: EspaciadoCampo.l),
      EsqueletoCampo(alto: 132, radio: 18),
      SizedBox(height: EspaciadoCampo.m),
      EsqueletoCampo(alto: 132, radio: 18),
    ],
  );
}
