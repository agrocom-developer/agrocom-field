import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

enum _EscenarioCondiciones { dentroDeRango, fueraDeRango }

/// 06 · Condiciones al abrir sesión (HU-06) — la pantalla "Clima" del mockup
/// ajustada al contrato real (`RegistroSync.tipo = condiciones`, ver
/// `docs/api/openapi.yaml` de `agrocom-api`): `viento_kmh`, `temperatura_c`
/// y `humedad_pct` en `momento: inicio_sesion`; si alguna medición cae fuera
/// de rango (viento > 17 km/h, temperatura > 30 °C, humedad > 90 %),
/// `observacion_agronomo` y `firma_observacion` pasan a ser obligatorias —
/// sin ambas el servidor rechaza el registro (`reglas_condiciones.dart`).
///
/// El selector alterna los dos escenarios para ver cómo aparece esa
/// exigencia. Lo que el mockup traía y el contrato no tiene, no se
/// reproduce: "Ráfagas" (pedido del dueño del 13/9/2026, sin campo todavía)
/// y "Dirección". Datos mock.
class CondicionesCampoVitrina extends StatefulWidget {
  const CondicionesCampoVitrina({super.key});

  @override
  State<CondicionesCampoVitrina> createState() =>
      _CondicionesCampoVitrinaState();
}

class _CondicionesCampoVitrinaState extends State<CondicionesCampoVitrina> {
  _EscenarioCondiciones _escenario = _EscenarioCondiciones.dentroDeRango;
  final _observacion = TextEditingController();
  final _firma = TextEditingController();

  @override
  void dispose() {
    _observacion.dispose();
    _firma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fuera = _escenario == _EscenarioCondiciones.fueraDeRango;
    final viento = fuera ? '21' : '9';
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronPulverizando,
      cobertura: CoberturaFondoFoto.superior,
      altoSuperior: 260,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoCampo(
                titulo: 'Condiciones al abrir sesión',
                subtitulo: 'condiciones · momento inicio_sesion',
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        '24°',
                        style: TipografiaCampo.tituloHero.copyWith(
                          fontSize: 72,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Lote 14 · captura manual 05:36',
                        style: TipografiaCampo.datoMono.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SelectorSegmentadoCampo<_EscenarioCondiciones>(
                      opciones: const [
                        (
                          _EscenarioCondiciones.dentroDeRango,
                          'Dentro de rango',
                        ),
                        (_EscenarioCondiciones.fueraDeRango, 'Fuera de rango'),
                      ],
                      seleccionado: _escenario,
                      onSeleccionar: (valor) =>
                          setState(() => _escenario = valor),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: StatChipCampo(
                            etiqueta: 'Viento',
                            valor: viento,
                            unidad: 'km/h',
                            notaAlerta: fuera ? 'Máx. orden 17' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: StatChipCampo(
                            etiqueta: 'Temperatura',
                            valor: '24',
                            unidad: '°C',
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: StatChipCampo(
                            etiqueta: 'Humedad',
                            valor: '61',
                            unidad: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (fuera) ...[
                      const BannerAlertaCampo(
                        texto: 'FUERA DE RANGO · VIENTO 21 > 17 KM/H',
                        valor: 'observación obligatoria',
                      ),
                      const SizedBox(height: 12),
                      CampoTextoCampo(
                        etiqueta: 'Observación del agrónomo',
                        controller: _observacion,
                      ),
                      const SizedBox(height: 12),
                      CampoTextoCampo(
                        etiqueta: 'Firma (texto plano)',
                        controller: _firma,
                      ),
                      const SizedBox(height: 12),
                      const NotaTecnicaCampo(
                        texto:
                            'observacion_agronomo + firma_observacion: sin las '
                            'dos, el servidor rechaza el registro y la sesión '
                            'no se abre. La firma es texto plano hasta TE-07.',
                      ),
                    ] else ...[
                      TarjetaCampo(
                        acento: ColoresCampo.acentoLima,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Apto para aplicar',
                              style: TipografiaCampo.tituloTarjeta.copyWith(
                                color: ColoresCampo.acentoLima,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Límites de la orden: viento ≤ 17 km/h · '
                              'temperatura ≤ 30 °C · humedad 40–90 %. Sin '
                              'observación del agrónomo.',
                              style: TipografiaCampo.notaMono.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const NotaTecnicaCampo(
                      texto:
                          'Ráfagas (km/h) y dirección del viento no están en '
                          'el contrato: ráfagas es un pedido del 13/9/2026 '
                          'pendiente del lado agrocom-api, no se captura.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BotonSecundarioCampo(
                      texto: 'Volver a medir',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonPrimarioCampo(
                      texto: 'Guardar condiciones',
                      onPressed: () {},
                    ),
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
