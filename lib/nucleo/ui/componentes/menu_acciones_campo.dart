import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Una acción del menú de [MenuAccionesCampo]. [destructiva] la pinta en
/// rojo (p. ej. "Eliminar", "Cancelar solicitud"); un `null` en [onElegir]
/// la muestra atenuada y sin poder tocarla.
@immutable
class AccionMenuCampo {
  const AccionMenuCampo({
    required this.texto,
    required this.icono,
    required this.onElegir,
    this.destructiva = false,
  });

  final String texto;
  final IconData icono;
  final VoidCallback? onElegir;
  final bool destructiva;
}

/// Menú de acciones en el encabezado (⋯) — agrupa lo secundario de una
/// pantalla en vez de sumar botones sueltos junto al título (principio de
/// "sin sobrecarga" del sistema visual). Cada ítem es un objetivo táctil de
/// 48 px (56 en modo campo) con ícono y texto, nunca solo uno de los dos.
class MenuAccionesCampo extends StatelessWidget {
  const MenuAccionesCampo({required this.acciones, this.tooltip, super.key});

  final List<AccionMenuCampo> acciones;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return PopupMenuButton<AccionMenuCampo>(
      tooltip: tooltip ?? l10n.menuAccionesMas,
      icon: Icon(Icons.more_vert_rounded, color: paleta.texto),
      color: paleta.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioCampo.media),
      ),
      constraints: const BoxConstraints(minWidth: 180),
      onSelected: (accion) => accion.onElegir?.call(),
      itemBuilder: (context) => [
        for (final accion in acciones)
          PopupMenuItem<AccionMenuCampo>(
            value: accion,
            enabled: accion.onElegir != null,
            height: ObjetivoTactilCampo.minimo,
            child: Row(
              children: [
                Icon(
                  accion.icono,
                  size: 20,
                  color: accion.onElegir == null
                      ? paleta.textoSecundario
                      : accion.destructiva
                      ? paleta.error
                      : paleta.texto,
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Flexible(
                  child: Text(
                    accion.texto,
                    style: TipografiaCampo.cuerpo.copyWith(
                      color: accion.onElegir == null
                          ? paleta.textoSecundario
                          : accion.destructiva
                          ? paleta.error
                          : paleta.texto,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
