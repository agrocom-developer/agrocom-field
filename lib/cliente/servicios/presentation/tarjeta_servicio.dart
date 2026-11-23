import 'package:flutter/material.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';

/// Resumen de un servicio para listas: lote, estado, proveedor y avance.
class TarjetaServicio extends StatelessWidget {
  const TarjetaServicio({
    required this.servicio,
    this.onTap,
    this.acciones = const [],
    this.resaltada = false,
    super.key,
  });

  final Servicio servicio;
  final VoidCallback? onTap;
  final List<Widget> acciones;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = servicio.proveedor;
    return SuperficieMarketplace(
      onTap: onTap,
      resaltada: resaltada,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(servicio.lote.nombre, style: texto.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${servicio.lote.zona} · '
                      '${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)}',
                      style: texto.bodyMedium?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InsigniaEstadoServicio(servicio.estado),
            ],
          ),
          if (servicio.estado == EstadoServicio.enEjecucion) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: servicio.progreso,
                minHeight: 8,
                backgroundColor: paleta.borde,
                color: paleta.acentoTexto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${FormatoMarketplace.hectareas(servicio.hectareasCubiertas)} de '
              '${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)}'
              '${servicio.etaMinutos != null ? ' · faltan ${FormatoMarketplace.duracionMinutos(servicio.etaMinutos!)}' : ''}',
              style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
            ),
          ],
          if (p != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                AvatarProveedor(p, tamano: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: texto.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CalificacionPromedio(valor: p.calificacion),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (servicio.estado == EstadoServicio.completado &&
              servicio.puntajeDelCliente != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: paleta.alerta),
                const SizedBox(width: 4),
                Text(
                  'Calificaste con ${servicio.puntajeDelCliente}',
                  style: texto.bodySmall?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [for (final a in acciones) Expanded(child: a)]),
          ],
        ],
      ),
    );
  }
}
