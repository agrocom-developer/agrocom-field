import 'package:flutter/material.dart';

import 'version_apk.dart';

/// Pantalla de bloqueo de HU-20 — sin vía de escape: `PopScope` impide
/// cerrarla con el botón/gesto "atrás" del sistema y no ofrece ninguna
/// acción para saltarla. Se monta por encima de cualquier otra pantalla
/// (ver `VersionBloqueoOverlay`) mientras el `version_code` instalado
/// quede por debajo de [minima].
class VersionBloqueadaPantalla extends StatelessWidget {
  const VersionBloqueadaPantalla({required this.minima, super.key});

  final VersionApk minima;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      key: const Key('version_bloqueada_pantalla'),
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actualización obligatoria',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta versión de la app ya no está autorizada. '
                    'Instalá la versión ${minima.version} o superior para '
                    'seguir usándola.',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descargala desde:',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    minima.urlDescarga,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
