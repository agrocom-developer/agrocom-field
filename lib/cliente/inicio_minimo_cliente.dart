import 'package:flutter/material.dart';

import '../nucleo/entorno/info_entorno.dart';
import '../nucleo/marketplace/ui/marketplace_ui.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/paleta_campo.dart';

/// Pantalla inicial del cliente cuando el build no es demo: logo, una línea y
/// el pie de entorno. Las pantallas de negocio con datos reales llegan con la
/// capa de datos de red (tareas 33 y 38 a 40 de la cola).
class InicioMinimoCliente extends StatelessWidget {
  const InicioMinimoCliente({required this.infoEntorno, super.key});

  final InfoEntorno infoEntorno;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const LogoAgrocomCampo(ancho: 200),
              const SizedBox(height: 24),
              Text(
                'Fumigación con drones, a pedido',
                style: texto.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Solicitá un servicio y seguilo en vivo.',
                style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const AvisoMarketplace(
                mensaje:
                    'Esta versión todavía no se conecta al servidor. Para ver '
                    'las pantallas con datos de ejemplo, compilá con el perfil '
                    'demo (config/env.demo.json).',
              ),
              const Spacer(),
              Text(
                '${infoEntorno.flavor.name.toUpperCase()} · '
                '${infoEntorno.hostApi} · v${infoEntorno.version}',
                style: texto.labelSmall?.copyWith(
                  color: paleta.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
