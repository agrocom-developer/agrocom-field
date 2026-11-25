import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Qué se le cuenta al piloto sobre la sincronización. No es
/// el estado de una fila del outbox ni el del motor: es su traducción a lo
/// que se ve en pantalla.
enum EstadoSyncVisibleCampo {
  /// El registro ya está en el dispositivo y espera señal para enviarse.
  guardadoLocal,

  /// El motor está corriendo un ciclo de envío ahora.
  sincronizando,

  /// El último ciclo terminó sin novedades por enviar.
  sincronizado,

  /// El último ciclo no pudo completarse; se reintenta solo.
  sinSincronizar,
}

/// Pastilla de estado de sincronización: ícono y texto en mono, nunca solo
/// color (sistema visual, §2). Va en el encabezado de las pantallas del
/// lote para que el offline-first se vea sin ocupar el lugar de la acción.
class EstadoSyncCampo extends StatelessWidget {
  const EstadoSyncCampo({required this.estado, this.detalle, super.key});

  final EstadoSyncVisibleCampo estado;

  /// Reemplaza el texto por defecto del estado (p. ej. «3 pendientes»).
  final String? detalle;

  static String etiquetaDe(EstadoSyncVisibleCampo estado) => switch (estado) {
    EstadoSyncVisibleCampo.guardadoLocal => 'En el dispositivo',
    EstadoSyncVisibleCampo.sincronizando => 'Sincronizando',
    EstadoSyncVisibleCampo.sincronizado => 'Sincronizado',
    EstadoSyncVisibleCampo.sinSincronizar => 'Sin sincronizar',
  };

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final (color, icono) = switch (estado) {
      EstadoSyncVisibleCampo.guardadoLocal => (
        paleta.textoSecundario,
        Icons.save_alt_rounded,
      ),
      EstadoSyncVisibleCampo.sincronizando => (paleta.info, Icons.sync_rounded),
      EstadoSyncVisibleCampo.sincronizado => (
        paleta.exito,
        Icons.cloud_done_rounded,
      ),
      EstadoSyncVisibleCampo.sinSincronizar => (
        paleta.alerta,
        Icons.cloud_off_rounded,
      ),
    };
    final texto = detalle ?? etiquetaDe(estado);
    return Semantics(
      label: 'Sincronización: $texto',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.s,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: EspaciadoCampo.s),
            Flexible(
              child: Text(
                texto.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TipografiaCampo.datoMonoDestacado.copyWith(
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
