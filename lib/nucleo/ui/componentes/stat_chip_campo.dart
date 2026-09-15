import 'package:flutter/material.dart';

import '../colores_campo.dart';
import 'tarjeta_campo.dart';

/// Label mono arriba + valor grande abajo, con una nota de alerta opcional
/// debajo (p. ej. "Ráfagas 21" en ámbar junto al viento sostenido). Uso
/// típico: tres en fila dentro de una `TarjetaCampo` (hectáreas/L-ha/vuelos,
/// viento/temperatura).
class StatChipCampo extends StatelessWidget {
  const StatChipCampo({
    required this.etiqueta,
    required this.valor,
    this.unidad,
    this.notaAlerta,
    super.key,
  });

  final String etiqueta;
  final String valor;
  final String? unidad;

  /// Texto corto en `acentoAmbar` debajo del valor (p. ej. "Ráfagas 21").
  /// `null` si no aplica.
  final String? notaAlerta;

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 1.2,
              color: ColoresCampo.textoPrincipal.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: ColoresCampo.textoPrincipal,
                  ),
                ),
                if (unidad != null)
                  TextSpan(
                    text: ' $unidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColoresCampo.textoPrincipal.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (notaAlerta != null) ...[
            const SizedBox(height: 6),
            Text(
              notaAlerta!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ColoresCampo.acentoAmbar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
