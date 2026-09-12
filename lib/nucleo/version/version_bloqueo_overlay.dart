import 'package:flutter/material.dart';

import 'estado_version.dart';
import 'version_bloqueada_pantalla.dart';

/// Envuelve el árbol raíz de la app para que [VersionBloqueadaPantalla]
/// tape cualquier pantalla —incluida la de login, sin sesión iniciada—
/// en cuanto [estadoVersion] emite `VersionBloqueada` (HU-20). Mismo patrón
/// de `Stack` que `EmergenciaBoton`: el bloqueo es infraestructura común a
/// los dos flavors, nunca una ruta que el usuario pueda navegar ni cerrar.
class VersionBloqueoOverlay extends StatelessWidget {
  const VersionBloqueoOverlay({
    required this.estadoVersion,
    required this.child,
    super.key,
  });

  final Stream<EstadoVersion> estadoVersion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EstadoVersion>(
      stream: estadoVersion,
      initialData: const VersionPermitida(),
      builder: (context, snapshot) {
        final estado = snapshot.data ?? const VersionPermitida();
        return Stack(
          children: [
            child,
            if (estado is VersionBloqueada)
              VersionBloqueadaPantalla(minima: estado.minima),
          ],
        );
      },
    );
  }
}
