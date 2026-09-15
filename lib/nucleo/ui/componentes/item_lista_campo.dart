import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tipografia_campo.dart';
import 'tarjeta_campo.dart';

/// Fila ícono/avatar + título/subtítulo + valor — patrón "line item" que se
/// repite para productos de una mezcla, baterías del reporte de equipos,
/// registros de la cola de sync o roles a elegir. Con [onTap] la fila
/// navega (y muestra un chevron a la derecha), como un `ListTile`.
class ItemListaCampo extends StatelessWidget {
  const ItemListaCampo({
    required this.titulo,
    this.subtitulo,
    this.valor,
    this.icono,
    this.iniciales,
    this.colorIcono = ColoresCampo.acentoLima,
    this.onTap,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
                      style: TipografiaCampo.datoMonoDestacado.copyWith(
                        fontWeight: FontWeight.w700,
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
                  style: TipografiaCampo.tituloTarjeta.copyWith(fontSize: 15),
                ),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitulo!, style: TipografiaCampo.datoMono),
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
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: ColoresCampo.textoPrincipal.withValues(
                alpha: OpacidadesCampo.secundaria,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
