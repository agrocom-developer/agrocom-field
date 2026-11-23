import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';

/// «★ 4,8 · 142 servicios» — estrella con ícono y número, para que no dependa
/// del color.
class CalificacionPromedio extends StatelessWidget {
  const CalificacionPromedio({required this.valor, this.detalle, super.key});

  final double valor;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      label:
          'Calificación ${valor.toStringAsFixed(1).replaceAll('.', ',')} de 5'
          '${detalle != null ? ', $detalle' : ''}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 18, color: paleta.alerta),
            const SizedBox(width: 4),
            Text(
              valor.toStringAsFixed(1).replaceAll('.', ','),
              style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (detalle != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '· $detalle',
                  overflow: TextOverflow.ellipsis,
                  style: texto.bodySmall?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
