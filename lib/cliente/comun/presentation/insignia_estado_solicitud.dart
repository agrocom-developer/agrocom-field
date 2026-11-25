import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Estado de una solicitud: ícono + texto sobre un fondo tenue. El color
/// nunca es el único portador del estado (sistema visual, §2).
class InsigniaEstadoSolicitud extends StatelessWidget {
  const InsigniaEstadoSolicitud(this.estado, {this.ofertas, super.key});

  final EstadoSolicitud estado;

  /// Cuántas ofertas vigentes tiene; con valor, se suma a la etiqueta de
  /// «Buscando piloto».
  final int? ofertas;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final (rol, icono) = switch (estado) {
      EstadoSolicitud.borrador => (
        paleta.textoSecundario,
        Icons.edit_note_rounded,
      ),
      EstadoSolicitud.abierta => (paleta.alerta, Icons.travel_explore_rounded),
      EstadoSolicitud.conOfertas => (
        paleta.acentoTexto,
        Icons.local_offer_rounded,
      ),
      EstadoSolicitud.adjudicada => (paleta.info, Icons.how_to_reg_rounded),
      EstadoSolicitud.enEjecucion => (paleta.acentoTexto, Icons.flight_rounded),
      EstadoSolicitud.finalizada => (paleta.exito, Icons.task_alt_rounded),
      EstadoSolicitud.calificada => (paleta.exito, Icons.star_rounded),
      EstadoSolicitud.disputada => (paleta.error, Icons.gavel_rounded),
      EstadoSolicitud.expirada => (
        paleta.textoSecundario,
        Icons.hourglass_disabled_rounded,
      ),
      EstadoSolicitud.cancelada => (paleta.error, Icons.cancel_rounded),
    };
    final etiqueta = estado == EstadoSolicitud.conOfertas && ofertas != null
        ? '$ofertas ${ofertas == 1 ? 'oferta' : 'ofertas'}'
        : estado.etiqueta;
    // Con texto grande la etiqueta baja de renglón en vez de desbordar.
    final (:fondo, texto: color) = paleta.contenedorDe(rol);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.6,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(RadioCampo.capsula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
