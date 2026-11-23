import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/calificar_pantalla.dart';
import '../domain/seguimiento_repositorio.dart';

/// Mapa a pantalla completa con una hoja inferior arrastrable (peek 30 %,
/// expandida 70 %): estado, avance, proveedor y ETA (sistema visual, §9).
class SeguimientoPantalla extends StatelessWidget {
  const SeguimientoPantalla({required this.servicio, super.key});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton.filled(
            tooltip: 'Volver',
            style: IconButton.styleFrom(
              backgroundColor: context.paleta.superficie,
              foregroundColor: context.paleta.texto,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: StreamEstable<SeguimientoVivo>(
        crear: () =>
            context.read<SeguimientoRepositorio>().observar(servicio.id),
        builder: (context, snap) {
          final f = snap.data;
          return Stack(
            children: [
              Positioned.fill(
                child: MapaLote(
                  lotes: [servicio.lote],
                  seleccionado: servicio.lote,
                  posicionDron: f?.posicionDron,
                  trazado: f?.trazado ?? const [],
                  relleno: const EdgeInsets.fromLTRB(40, 120, 40, 320),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.34,
                minChildSize: 0.22,
                maxChildSize: 0.72,
                snap: true,
                builder: (context, controlador) => _Hoja(
                  controlador: controlador,
                  servicio: servicio,
                  fotograma: f,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hoja extends StatelessWidget {
  const _Hoja({
    required this.controlador,
    required this.servicio,
    required this.fotograma,
  });

  final ScrollController controlador;
  final Servicio servicio;
  final SeguimientoVivo? fotograma;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final f = fotograma;
    final p = servicio.proveedor;
    final cubiertas = f?.hectareasCubiertas ?? servicio.hectareasCubiertas;
    final estado = f?.estado ?? servicio.estado;
    final terminado = estado == EstadoServicio.completado;
    return Container(
      decoration: BoxDecoration(
        color: paleta.superficieElevada,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: paleta.borde),
        boxShadow: const [BoxShadow(blurRadius: 24, color: Color(0x26000000))],
      ),
      child: ListView(
        controller: controlador,
        padding: const EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          EspaciadoCampo.s,
          EspaciadoCampo.l,
          EspaciadoCampo.xl,
        ),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: paleta.bordeFuerte,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  terminado ? 'Servicio completado' : 'Fumigando tu lote',
                  style: texto.titleLarge,
                ),
              ),
              InsigniaEstadoServicio(estado),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            FormatoMarketplace.hectareas(cubiertas),
            style: texto.displaySmall?.copyWith(color: paleta.acentoTexto),
          ),
          Text(
            'de ${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)}'
            '${f?.etaMinutos != null && !terminado ? ' · faltan ${FormatoMarketplace.duracionMinutos(f!.etaMinutos!)}' : ''}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: f?.progreso ?? servicio.progreso,
              minHeight: 10,
              backgroundColor: paleta.borde,
              color: paleta.acentoTexto,
            ),
          ),
          if (p != null) ...[
            const SizedBox(height: 20),
            SuperficieMarketplace(
              child: Row(
                children: [
                  AvatarProveedor(p),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, style: texto.titleMedium),
                        const SizedBox(height: 2),
                        CalificacionPromedio(
                          valor: p.calificacion,
                          detalle: p.tipo.etiqueta,
                        ),
                        if (servicio.dron != null)
                          Text(
                            '${servicio.dron!.modelo} · ${servicio.dron!.matricula}',
                            style: texto.bodySmall?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SuperficieMarketplace(
            child: Column(
              children: [
                _Fila('Producto', servicio.producto),
                const SizedBox(height: 8),
                _Fila(
                  'Caldo total',
                  FormatoMarketplace.litros(servicio.litrosTotales),
                ),
              ],
            ),
          ),
          if (terminado) ...[
            const SizedBox(height: 16),
            BotonPrimarioCampo(
              texto: 'Calificar al proveedor',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<bool>(
                  builder: (_) => CalificarPantalla(servicio: servicio),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: texto.bodyMedium?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
