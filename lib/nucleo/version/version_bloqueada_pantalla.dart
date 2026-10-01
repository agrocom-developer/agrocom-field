import 'package:flutter/material.dart';

import '../ui/colores_campo.dart';
import '../ui/componentes/componentes_campo.dart';
import '../ui/tipografia_campo.dart';
import 'version_apk.dart';

/// Pantalla de bloqueo de HU-20 — sin vía de escape: `PopScope` impide
/// cerrarla con el botón/gesto "atrás" del sistema y no ofrece ninguna
/// acción para saltarla. Se monta por encima de cualquier otra pantalla
/// (ver `VersionBloqueoOverlay`) mientras el `version_code` instalado
/// quede por debajo de [minima].
///
/// En modo campo (ADR 0008, decisión del 1/10/2026): fondo `fondoProfundo`,
/// tipografía y tarjeta del catálogo. Sin pie de entorno/versión: esta
/// pantalla solo recibe [minima], y sumarle lectura de configuración no es
/// parte de una migración visual.
class VersionBloqueadaPantalla extends StatelessWidget {
  const VersionBloqueadaPantalla({required this.minima, super.key});

  final VersionApk minima;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      key: const Key('version_bloqueada_pantalla'),
      canPop: false,
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.system_update_rounded,
                    size: 56,
                    color: ColoresCampo.acentoAmbar,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Actualización obligatoria',
                    style: TipografiaCampo.tituloPantalla,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta versión de la app ya no está autorizada. '
                    'Instalá la versión ${minima.version} o superior para '
                    'seguir usándola.',
                    style: TipografiaCampo.cuerpo,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TarjetaCampo(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESCARGALA DESDE',
                          style: TipografiaCampo.etiquetaMono,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          minima.urlDescarga,
                          style: TipografiaCampo.datoMonoDestacado.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
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
