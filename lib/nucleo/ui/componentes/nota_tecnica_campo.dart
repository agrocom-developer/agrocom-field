import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Texto mono chico y atenuado dentro de una tarjeta sutil — expone el
/// estado de sync en la propia pantalla (p. ej. "se guarda local y queda
/// pendiente de sync"), coherente con la invariante 1 de `CLAUDE.md`: el
/// offline-first se ve, no se esconde.
class NotaTecnicaCampo extends StatelessWidget {
  const NotaTecnicaCampo({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresCampo.textoPrincipal.withValues(alpha: 0.04),
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.6,
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
