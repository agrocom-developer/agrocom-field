import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/perfil_repositorio.dart';

/// Perfil del proveedor: encabezado con calificación, hectáreas por mes,
/// documentos y reseñas recientes. Sin métricas decorativas (sistema visual,
/// §9).
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({this.reloj = DateTime.now, super.key});

  final DateTime Function() reloj;

  static Future<(Proveedor, List<HectareasMensuales>)> _cargar(
    PerfilRepositorio repo,
  ) async => (await repo.perfil(), await repo.hectareasPorMes());

  @override
  Widget build(BuildContext context) {
    return FuturoEstable<(Proveedor, List<HectareasMensuales>)>(
      crear: () => _cargar(context.read<PerfilRepositorio>()),
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          return const Padding(
            padding: EdgeInsets.all(EspaciadoCampo.l),
            child: EsqueletoCampo(alto: 200),
          );
        }
        final (p, meses) = d;
        final texto = Theme.of(context).textTheme;
        final paleta = context.paleta;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Row(
              children: [
                AvatarProveedor(p, tamano: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre, style: texto.titleLarge),
                      Text(
                        p.tipo.etiqueta,
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CalificacionPromedio(
                        valor: p.calificacion,
                        detalle: '${p.serviciosCompletados} servicios',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Zonas de cobertura', style: texto.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final z in p.zonas)
                  Chip(
                    avatar: const Icon(Icons.place_outlined, size: 16),
                    label: Text(z),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Hectáreas por mes', style: texto.titleLarge),
            const SizedBox(height: 12),
            SuperficieMarketplace(
              child: SizedBox(
                height: 180,
                child: _GraficoHectareas(meses: meses),
              ),
            ),
            const SizedBox(height: 24),
            Text('Documentos', style: texto.titleLarge),
            const SizedBox(height: 12),
            for (final doc in p.documentos) ...[
              _FilaDocumento(documento: doc),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Text('Reseñas recientes', style: texto.titleLarge),
            const SizedBox(height: 12),
            for (final r in p.resenas) ...[
              SuperficieMarketplace(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r.autor, style: texto.titleSmall)),
                        CalificacionCampo(valor: r.puntaje, tamano: 18),
                      ],
                    ),
                    Text(
                      FormatoMarketplace.hace(r.fecha, reloj()),
                      style: texto.bodySmall?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                    if (r.comentario != null) ...[
                      const SizedBox(height: 6),
                      Text(r.comentario!, style: texto.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _FilaDocumento extends StatelessWidget {
  const _FilaDocumento({required this.documento});

  final DocumentoProveedor documento;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final (color, icono) = switch (documento.estado) {
      EstadoDocumento.vigente => (paleta.exito, Icons.verified_rounded),
      EstadoDocumento.porVencer => (paleta.alerta, Icons.schedule_rounded),
      EstadoDocumento.enRevision => (paleta.info, Icons.hourglass_top_rounded),
      EstadoDocumento.rechazado => (paleta.error, Icons.cancel_rounded),
    };
    return SuperficieMarketplace(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(documento.nombre, style: texto.titleSmall),
                Text(
                  documento.vence != null
                      ? '${documento.estado.etiqueta} · vence ${FormatoMarketplace.fechaLarga(documento.vence!)}'
                      : documento.estado.etiqueta,
                  style: texto.bodySmall?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoHectareas extends StatelessWidget {
  const _GraficoHectareas({required this.meses});

  final List<HectareasMensuales> meses;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final estilo = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: paleta.textoSecundario);
    // Conversión a `double` solo para dibujar la barra: el valor mostrado
    // sigue siendo el `Decimal` (ADR 0002).
    final altos = [for (final m in meses) m.hectareas.toDouble()];
    return Semantics(
      label:
          'Gráfico de barras de hectáreas por mes: ${[for (final m in meses) '${m.etiqueta} ${FormatoMarketplace.hectareas(m.hectareas)}'].join(', ')}',
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
                  reservedSize: 24,
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
                        top: Radius.circular(6),
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
