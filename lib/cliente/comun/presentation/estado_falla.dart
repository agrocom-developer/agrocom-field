import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Pantalla que no pudo cargar: dice qué pasó y ofrece la salida. Distingue
/// la falta de red (se resuelve sola al volver la señal) de un error.
class EstadoFalla extends StatelessWidget {
  const EstadoFalla({
    required this.sinConexion,
    required this.alReintentar,
    this.queNoCargo = 'esta pantalla',
    super.key,
  });

  final bool sinConexion;
  final VoidCallback alReintentar;

  /// Completa «No pudimos cargar …».
  final String queNoCargo;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspaciadoCampo.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sinConexion
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: EspaciadoCampo.xxxl,
              color: paleta.textoSecundario,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              sinConexion ? 'Sin conexión' : 'Algo salió mal',
              style: texto.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Text(
              sinConexion
                  ? 'Necesitamos señal para cargar $queNoCargo. Revisá tu '
                        'conexión y probá de nuevo.'
                  : 'No pudimos cargar $queNoCargo. Probá de nuevo en un '
                        'momento.',
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
