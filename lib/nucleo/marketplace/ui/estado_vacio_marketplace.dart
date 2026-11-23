import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';

/// Estado vacío o de error de una lista: ícono, una línea y apoyo.
class EstadoVacioMarketplace extends StatelessWidget {
  const EstadoVacioMarketplace({
    required this.icono,
    required this.titulo,
    this.detalle,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: paleta.textoSecundario),
            const SizedBox(height: 12),
            Text(titulo, style: texto.titleMedium, textAlign: TextAlign.center),
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Text(
                detalle!,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
