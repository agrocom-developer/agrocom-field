import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 01 · Onboarding — "El lote no tiene señal. La app sí.", recreada del
/// mockup de referencia (ADR 0008) sobre `ImagenesCampo.dronPulverizandoVertical`.
class OnboardingCampoVitrina extends StatelessWidget {
  const OnboardingCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronPulverizandoVertical,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
                    border: Border.all(
                      color: ColoresCampo.textoPrincipal.withValues(
                        alpha: 0.16,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'PILOTO · v0.15',
                    style: TipografiaCampo.datoMonoDestacado.copyWith(
                      color: ColoresCampo.textoPrincipal,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text.rich(
                TextSpan(
                  style: TipografiaCampo.tituloHero,
                  children: [
                    TextSpan(text: 'El lote no\ntiene señal.\n'),
                    TextSpan(
                      text: 'La app sí.',
                      style: TextStyle(color: ColoresCampo.acentoLima),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cargás la aplicación, las evidencias y el caldo sin '
                'conexión. Se sincroniza cuando vuelve.',
                style: TipografiaCampo.cuerpo,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: BotonPrimarioCampo(
                      texto: 'Comenzar',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  BotonCircularCampo(
                    icono: Icons.arrow_forward,
                    tamano: 56,
                    tooltip: 'Siguiente',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
