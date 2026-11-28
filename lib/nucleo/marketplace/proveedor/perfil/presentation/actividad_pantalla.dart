import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/marketplace_ui.dart';

/// Hectáreas por mes y zonas de cobertura del proveedor. Salen del perfil:
/// allí solo queda el enlace «Hectáreas y zonas».
class ActividadPantalla extends StatelessWidget {
  const ActividadPantalla({
    required this.meses,
    required this.zonas,
    super.key,
  });

  final List<HectareasMensuales> meses;
  final List<String> zonas;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    Widget titulo(String s) => Padding(
      padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
      child: Semantics(header: true, child: Text(s, style: texto.titleLarge)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.perfilPilActividad)),
      body: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: EntradaCampo.escalonar([
          titulo(t.perfilProveedorHectareasMes),
          if (meses.every((m) => m.hectareas.sign <= 0))
            Text(t.perfilProveedorHectareasMesVacio, style: texto.bodyMedium)
          else
            SuperficieMarketplace(
              child: SizedBox(
                height: 180,
                child: GraficoHectareasProveedor(meses: meses),
              ),
            ),
          const SizedBox(height: EspaciadoCampo.xl),
          titulo(t.perfilProveedorZonas),
          Wrap(
            spacing: EspaciadoCampo.s,
            runSpacing: EspaciadoCampo.s,
            children: [
              for (final z in zonas)
                ChipEstadoMarketplace(
                  etiqueta: z,
                  etiquetaSemantica: t.perfilProveedorZonaSemantica(z),
                  tono: TonoEstado.neutro,
                  icono: Icons.place_outlined,
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class GraficoHectareasProveedor extends StatelessWidget {
  const GraficoHectareasProveedor({required this.meses, super.key});

  final List<HectareasMensuales> meses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final estilo = Theme.of(context).textTheme.labelSmall;
    // Conversión a `double` solo para dibujar la barra: el valor mostrado
    // sigue siendo el `Decimal` (ADR 0002).
    final altos = [for (final m in meses) m.hectareas.toDouble()];
    return Semantics(
      container: true,
      label: l10n.proveedorPerfilGraficoBarras(
        [
          for (final m in meses)
            '${m.etiqueta} ${FormatoMarketplace.hectareas(m.hectareas)}',
        ].join(', '),
      ),
      child: ExcludeSemantics(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (altos.fold<double>(0, (a, b) => a > b ? a : b) * 1.15),
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
                  reservedSize: MediaQuery.textScalerOf(context).scale(24),
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(meses[v.toInt()].etiqueta, style: estilo),
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
                      width: 22,
                      color: i == altos.length - 1
                          ? paleta.acentoTexto
                          : paleta.acentoTexto.withValues(alpha: 0.45),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(RadioCampo.xs),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
