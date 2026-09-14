import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Franja de alerta (offline, ráfagas fuera de rango) — fila con [texto] a
/// la izquierda y [valor] opcional a la derecha (p. ej. "SIN CONEXIÓN ·
/// LOTE" / "4 pendientes ↑").
class BannerAlertaCampo extends StatelessWidget {
  const BannerAlertaCampo({required this.texto, this.valor, super.key});

  final String texto;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ColoresCampo.acentoAmbar.withValues(alpha: 0.12),
        border: Border.all(
          color: ColoresCampo.acentoAmbar.withValues(alpha: 0.32),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColoresCampo.acentoAmbarTexto,
              ),
            ),
          ),
          if (valor != null) ...[
            const SizedBox(width: 12),
            Text(
              valor!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColoresCampo.acentoAmbarTexto,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
