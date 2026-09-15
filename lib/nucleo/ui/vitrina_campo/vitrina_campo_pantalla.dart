import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../tema_campo.dart';
import 'cola_sync_campo_vitrina.dart';
import 'crear_aplicacion_campo_vitrina.dart';
import 'inicio_piloto_campo_vitrina.dart';
import 'login_dispositivo_campo_vitrina.dart';
import 'onboarding_campo_vitrina.dart';

/// Vista previa del modo "campo" (ADR 0008) — recrea cinco de las nueve
/// pantallas del mockup de referencia del dueño con los widgets reales del
/// catálogo (`lib/nucleo/ui/componentes/`), para verlas corriendo en un
/// dispositivo real antes de decidir qué pantalla migra de verdad a este
/// modo.
///
/// Ninguna de las cinco lee de `drift` ni escribe al outbox — los datos son
/// constantes hardcodeadas, igual que el HTML de origen (ver ADR 0008: "el
/// HTML es un demo para extraer el lenguaje visual... no una especificación
/// de datos"). No forma parte del flujo real de ningún flavor: solo se llega
/// desde un acceso de depuración (`kDebugMode`).
class VitrinaCampoPantalla extends StatefulWidget {
  const VitrinaCampoPantalla({super.key});

  @override
  State<VitrinaCampoPantalla> createState() => _VitrinaCampoPantallaState();
}

class _VitrinaCampoPantallaState extends State<VitrinaCampoPantalla> {
  int _indice = 0;

  static const _opciones = [
    (0, 'Onboard'),
    (1, 'Login'),
    (2, 'Inicio'),
    (3, 'Crear'),
    (4, 'Sync'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    BotonCircularCampo(
                      icono: Icons.close,
                      tooltip: 'Cerrar vista previa',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectorSegmentadoCampo<int>(
                        opciones: _opciones,
                        seleccionado: _indice,
                        onSeleccionar: (valor) =>
                            setState(() => _indice = valor),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _indice,
                  children: const [
                    OnboardingCampoVitrina(),
                    LoginDispositivoCampoVitrina(),
                    InicioPilotoCampoVitrina(),
                    CrearAplicacionCampoVitrina(),
                    ColaSyncCampoVitrina(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
