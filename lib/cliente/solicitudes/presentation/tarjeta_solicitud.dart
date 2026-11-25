import 'package:flutter/material.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../comun/presentation/insignia_estado_solicitud.dart';
import '../domain/solicitud.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Resumen de una solicitud para listas: lote, estado, precio por hectárea,
/// ofertas o avance, y el piloto elegido.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({
    required this.solicitud,
    this.onTap,
    this.acciones = const [],
    this.resaltada = false,
    super.key,
  });

  final Solicitud solicitud;
  final VoidCallback? onTap;
  final List<Widget> acciones;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = solicitud;
    final conteoOfertas = s.estado == EstadoSolicitud.conOfertas
        ? s.ofertasVigentes
        : null;
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
                    Text(s.lote.nombre, style: texto.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${s.lote.zona} · ${s.cultivo} · '
                      '${FormatoMarketplace.hectareas(s.hectareas)}',
                      style: texto.bodyMedium?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: InsigniaEstadoSolicitud(
                  s.estado,
                  ofertas: conteoOfertas,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.precioHaAcordado != null
                ? '${FormatoMarketplace.bs(s.precioHaAcordado!)}/ha acordado · '
                      '${FormatoMarketplace.bs(s.totalAPagar)}'
                : '${FormatoMarketplace.bs(s.precioHaPropuesto)}/ha propuesto',
            style: texto.titleSmall,
          ),
          if (s.estado == EstadoSolicitud.enEjecucion) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(RadioCampo.capsula),
              child: LinearProgressIndicator(
                value: s.progreso,
                minHeight: 8,
                backgroundColor: paleta.borde,
                color: paleta.acentoTexto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${s.porcentajeAvance?.toStringAsFixed(0) ?? '0'} % de '
              '${FormatoMarketplace.hectareas(s.hectareas)}',
              style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
            ),
          ],
          if (s.nombreProveedor != null && s.estado.conPiloto) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: paleta.textoSecundario,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.nombreProveedor!,
                    style: texto.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (s.estado == EstadoSolicitud.calificada &&
              s.puntajeDelCliente != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: paleta.alerta),
                const SizedBox(width: 4),
                Text(
                  'Calificaste con ${s.puntajeDelCliente}',
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
