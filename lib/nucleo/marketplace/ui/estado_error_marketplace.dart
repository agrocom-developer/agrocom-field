import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';

/// Error de carga con salida: qué pasó y un botón para volver a intentar.
class EstadoErrorMarketplace extends StatelessWidget {
  const EstadoErrorMarketplace({
    required this.titulo,
    required this.onReintentar,
    this.detalle,
    super.key,
  });

  final String titulo;
  final String? detalle;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: paleta.textoSecundario,
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
            if (detalle != null) ...[
              const SizedBox(height: EspaciadoCampo.xs),
              Text(
                detalle!,
                style: texto.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
