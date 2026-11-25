import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';

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
    final rol = switch (tono) {
      TonoAviso.info => paleta.info,
      TonoAviso.alerta => paleta.alerta,
      TonoAviso.error => paleta.error,
    };
    // Par tonal del rol: fondo y texto con contraste medido (sin alpha).
    final (:fondo, texto: colorTexto) = paleta.contenedorDe(rol);
    final icon =
        icono ??
        switch (tono) {
          TonoAviso.info => Icons.info_outline_rounded,
          TonoAviso.alerta => Icons.warning_amber_rounded,
          TonoAviso.error => Icons.error_outline_rounded,
        };
    return Container(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(RadioCampo.media),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorTexto, size: 22),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorTexto),
            ),
          ),
        ],
      ),
    );
  }
}
