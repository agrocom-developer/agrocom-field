import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/demo/recorrido_demo.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicio_asignado_repositorio.dart';

/// Servicio vigente del piloto en modo campo: un dato protagonista (hectáreas
/// cubiertas), el lote en el mapa y la acción principal de 56 px. Todo viene
/// del repositorio local: sin esqueleto, sin espera de red (sistema visual,
/// §9).
class ServicioAsignadoPantalla extends StatelessWidget {
  const ServicioAsignadoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return StreamEstable<List<Servicio>>(
      crear: () => context.read<ServicioAsignadoRepositorio>().observar(),
      builder: (context, snap) {
        // Lectura local: sin esqueleto; el primer cuadro queda vacío.
        if (snap.data == null) return const SizedBox.shrink();
        final lista = snap.data!;
        if (lista.isEmpty) {
          return const EstadoVacioMarketplace(
            icono: Icons.flight_takeoff_rounded,
            titulo: 'Sin servicio asignado',
            detalle:
                'Aceptá una oferta y el servicio aparece acá, listo '
                'para trabajar sin señal.',
          );
        }
        final actual = lista.first;
        final proximos = lista.skip(1).toList();
        final recorrido = RecorridoDemo.paraLote(actual.lote);
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Row(
              children: [
                Expanded(child: Text('Servicio', style: texto.headlineMedium)),
                InsigniaEstadoServicio(actual.estado),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${actual.lote.nombre} · ${actual.lote.zona}',
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: 16),
            SuperficieMarketplace(
              resaltada: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HECTÁREAS CUBIERTAS',
                    style: texto.labelSmall?.copyWith(
                      color: paleta.textoSecundario,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatoMarketplace.hectareas(actual.hectareasCubiertas),
                    style: texto.displaySmall?.copyWith(
                      color: paleta.acentoTexto,
                    ),
                  ),
                  Text(
                    'de ${FormatoMarketplace.hectareas(actual.hectareasDeclaradas)}',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: actual.progreso,
                      minHeight: 10,
                      backgroundColor: paleta.borde,
                      color: paleta.acentoTexto,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                child: MapaLote(
                  lotes: [actual.lote],
                  seleccionado: actual.lote,
                  posicionDron: recorrido.en(actual.progreso),
                  trazado: recorrido.trazadoHasta(actual.progreso),
                  interactivo: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SuperficieMarketplace(
              child: Column(
                children: [
                  _Fila('Producto', actual.producto),
                  _Fila(
                    'Dosis',
                    '${FormatoMarketplace.numero(actual.dosisLitrosPorHectarea, decimales: 1)} L/ha',
                  ),
                  _Fila(
                    'Caldo total',
                    FormatoMarketplace.litros(actual.litrosTotales),
                  ),
                  _Fila('Cliente', actual.clienteNombre),
                  if (actual.dron != null)
                    _Fila(
                      'Dron',
                      '${actual.dron!.modelo} · ${actual.dron!.matricula}',
                    ),
                  _Fila(
                    'Pago',
                    FormatoMarketplace.bs(actual.precio),
                    ultimo: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BotonPrimarioCampo(
              texto: actual.estado == EstadoServicio.enEjecucion
                  ? 'Abrir sesión de vuelo'
                  : 'Iniciar servicio',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La sesión de vuelo llega con la tarea 46 de la cola.',
                  ),
                ),
              ),
            ),
            if (proximos.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Próximos', style: texto.titleLarge),
              const SizedBox(height: 12),
              for (final s in proximos) ...[
                SuperficieMarketplace(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.lote.nombre, style: texto.titleMedium),
                            Text(
                              '${s.lote.zona} · ${FormatoMarketplace.hectareas(s.hectareasDeclaradas)} · '
                              '${FormatoMarketplace.fechaCorta(s.fechaDeseada)}',
                              style: texto.bodySmall?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatoMarketplace.bs(s.precio),
                        style: texto.titleSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.ultimo = false});

  final String etiqueta;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: texto.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
