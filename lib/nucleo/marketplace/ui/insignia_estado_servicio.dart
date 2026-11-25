import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../dominio/dominio.dart';
import '../../ui/tokens_campo.dart';

/// Estado de un servicio: ícono + texto sobre un fondo tenue. El color nunca
/// es el único portador del estado (sistema visual, §2).
class InsigniaEstadoServicio extends StatelessWidget {
  const InsigniaEstadoServicio(this.estado, {super.key});

  final EstadoServicio estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final (rol, icono) = switch (estado) {
      EstadoServicio.buscandoProveedor => (paleta.alerta, Icons.radar_rounded),
      EstadoServicio.asignado => (paleta.info, Icons.how_to_reg_rounded),
      EstadoServicio.enEjecucion => (paleta.acentoTexto, Icons.flight_rounded),
      EstadoServicio.completado => (paleta.exito, Icons.check_circle_rounded),
      EstadoServicio.cancelado => (paleta.error, Icons.cancel_rounded),
    };
    // Con texto grande la etiqueta baja de renglón en vez de desbordar: el
    // ancho máximo da un límite al `Row` aunque el padre no lo dé.
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
                estado.etiqueta,
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
