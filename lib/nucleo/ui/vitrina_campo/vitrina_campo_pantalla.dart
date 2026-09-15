import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../tema_campo.dart';
import 'cola_sync_campo_vitrina.dart';
import 'condiciones_campo_vitrina.dart';
import 'crear_aplicacion_campo_vitrina.dart';
import 'inicio_decision_campo_vitrina.dart';
import 'inicio_piloto_campo_vitrina.dart';
import 'login_dispositivo_campo_vitrina.dart';
import 'onboarding_campo_vitrina.dart';
import 'orden_detalle_campo_vitrina.dart';
import 'reporte_equipos_campo_vitrina.dart';

/// Vista previa del modo "campo" (ADR 0008) — recrea las pantallas del
/// mockup de referencia del dueño (las nueve de la ronda 1 menos la mezcla,
/// fuera por pedido del dueño, más la variante 1b de inicio) con los widgets
/// reales del catálogo (`lib/nucleo/ui/componentes/`) y con los campos del
/// contrato real de `agrocom-api` donde el mockup se apartaba de él, para
/// verlas corriendo en un dispositivo real antes de decidir qué pantalla
/// migra de verdad a este modo.
///
/// Ninguna lee de `drift` ni escribe al outbox — los datos son
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
    (3, 'Inicio B'),
    (4, 'Crear'),
    (5, 'Clima'),
    (6, 'Equipos'),
    (7, 'Orden'),
    (8, 'Sync'),
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
                        desplazable: true,
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
                    InicioDecisionCampoVitrina(),
                    CrearAplicacionCampoVitrina(),
                    CondicionesCampoVitrina(),
                    ReporteEquiposCampoVitrina(),
                    OrdenDetalleCampoVitrina(),
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
