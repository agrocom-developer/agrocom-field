import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/estado_error_marketplace.dart';

/// Pantalla que no pudo cargar: dice qué pasó y ofrece la salida. Distingue
/// la falta de red (se resuelve sola al volver la señal) de un error. Es el
/// patrón de la pantalla 21 (`EstadoErrorMarketplace`) con los textos del
/// cliente.
class EstadoFalla extends StatelessWidget {
  const EstadoFalla({
    required this.sinConexion,
    required this.alReintentar,
    this.queNoCargo,
    super.key,
  });

  final bool sinConexion;
  final VoidCallback alReintentar;

  /// Completa «No pudimos cargar …»; por defecto, «esta pantalla».
  final String? queNoCargo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final que = queNoCargo ?? t.estadoErrorEstaPantalla;
    return EstadoErrorMarketplace(
      sinConexion: sinConexion,
      titulo: sinConexion ? t.estadoSinConexionTitulo : t.estadoErrorTitulo,
      detalle: sinConexion
          ? t.estadoSinConexionDetalle(que)
          : t.estadoErrorDetalle(que),
      onReintentar: alReintentar,
    );
  }
}
