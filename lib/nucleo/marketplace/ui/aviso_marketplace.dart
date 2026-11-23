import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';

enum TonoAviso { info, alerta, error }

/// Aviso en línea: ícono + texto sobre un fondo tenue del tono (el ícono y el
/// texto portan el significado, no solo el color).
class AvisoMarketplace extends StatelessWidget {
  const AvisoMarketplace({
    required this.mensaje,
    this.tono = TonoAviso.info,
    this.icono,
    super.key,
  });

  final String mensaje;
  final TonoAviso tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final color = switch (tono) {
      TonoAviso.info => paleta.info,
      TonoAviso.alerta => paleta.alerta,
      TonoAviso.error => paleta.error,
    };
    final icon =
        icono ??
        switch (tono) {
          TonoAviso.info => Icons.info_outline_rounded,
          TonoAviso.alerta => Icons.warning_amber_rounded,
          TonoAviso.error => Icons.error_outline_rounded,
        };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: paleta.texto),
            ),
          ),
        ],
      ),
    );
  }
}
