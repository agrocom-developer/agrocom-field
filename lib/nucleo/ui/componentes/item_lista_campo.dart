import 'package:flutter/material.dart';

import '../colores_campo.dart';
import 'tarjeta_campo.dart';

/// Fila ícono/avatar + título/subtítulo + valor — patrón "line item" que se
/// repite para productos de una mezcla, baterías del reporte de equipos o
/// registros de la cola de sync.
class ItemListaCampo extends StatelessWidget {
  const ItemListaCampo({
    required this.titulo,
    this.subtitulo,
    this.valor,
    this.icono,
    this.iniciales,
    this.colorIcono = ColoresCampo.acentoLima,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final String? valor;

  /// Ícono Material del avatar cuadrado. Si es `null` y [iniciales] no lo
  /// es, se muestra texto corto en su lugar (p. ej. "GLI").
  final IconData? icono;
  final String? iniciales;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icono != null || iniciales != null) ...[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: icono != null
                  ? Icon(icono, color: colorIcono, size: 18)
                  : Text(
                      iniciales!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colorIcono,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: ColoresCampo.textoPrincipal,
                  ),
                ),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitulo!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: ColoresCampo.textoPrincipal.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (valor != null)
            Text(
              valor!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ColoresCampo.textoPrincipal,
              ),
            ),
        ],
      ),
    );
  }
}
