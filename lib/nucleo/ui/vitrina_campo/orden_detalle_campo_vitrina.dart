import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 08 · Detalle de orden / lote offline (HU-04) — ajustada al contrato real
/// de `OrdenCatalogo` (`GET /api/sync/catalogo`, `docs/api/openapi.yaml`
/// de `agrocom-api`): `lotes[]` con `hectareas_solicitadas` por lote
/// (HU-92), `litros_ha` O `kilos_por_vuelo` según el insumo (HU-79), los
/// límites climáticos y los parámetros de vuelo acordados. Todo leído de
/// `drift` en la pantalla real; acá datos mock. El CTA es el real de HU-05:
/// abrir trabajo.
///
/// Lo que el mockup traía y el catálogo no: establecimiento, campaña y
/// cultivo (viven en Comercial, no viajan en el pull), y el ítem "Mezcla
/// del caldo" (fuera de la vista previa por pedido del dueño, 14/9/2026).
class OrdenDetalleCampoVitrina extends StatelessWidget {
  const OrdenDetalleCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    final fila = TipografiaCampo.datoMono.copyWith(
      fontSize: 13,
      color: ColoresCampo.textoPrincipal.withValues(
        alpha: OpacidadesCampo.media,
      ),
    );
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronPulverizandoVertical,
      cobertura: CoberturaFondoFoto.superior,
      altoSuperior: 320,
      alineacion: const Alignment(0, -0.3),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                children: [
                  BotonCircularCampo(
                    icono: Icons.arrow_back,
                    tooltip: 'Volver',
                    onPressed: () {},
                  ),
                  const Spacer(),
                  const BadgeEstadoCampo(
                    texto: 'descargado · catálogo local',
                    estado: EstadoBadgeCampo.ok,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 150, 18, 12),
                children: [
                  TarjetaCampo(
                    tamano: TamanoTarjetaCampo.grande,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDEN 2431 · APLICACIÓN N.º 3',
                          style: TipografiaCampo.etiquetaMono.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Lote 14 — La Nena',
                          style: TipografiaCampo.valorDestacado,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Contrato 118 · emitida 2026-09-10 · vigente',
                          style: TipografiaCampo.cuerpoSecundario,
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(
                              child: StatChipCampo(
                                etiqueta: 'Dosis',
                                valor: '12',
                                unidad: 'L/ha',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: StatChipCampo(
                                etiqueta: 'Viento máx',
                                valor: '17',
                                unidad: 'km/h',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Expanded(
                              child: StatChipCampo(
                                etiqueta: 'Temp. máx',
                                valor: '30',
                                unidad: '°C',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: StatChipCampo(
                                etiqueta: 'Humedad',
                                valor: '40–90',
                                unidad: '%',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TarjetaCampo(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lotes de la orden',
                              style: TipografiaCampo.tituloTarjeta,
                            ),
                            Text(
                              '60,5 ha en total',
                              style: TipografiaCampo.datoMonoDestacado,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final lote in const [
                          ('Lote 14 · La Nena', '42,5 ha'),
                          ('Lote 15 · El Bajo', '18,0 ha'),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lote.$1, style: fila),
                                Text(lote.$2, style: fila),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TarjetaCampo(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parámetros de vuelo acordados',
                          style: TipografiaCampo.tituloTarjeta,
                        ),
                        const SizedBox(height: 12),
                        for (final parametro in const [
                          ('altura_vuelo_m', '3,0 m'),
                          ('velocidad_vuelo_kmh', '6,0 km/h'),
                          ('velocidad_max_kmh', '8,0 km/h'),
                          ('ancho_pasada_m', '5,5 m'),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(parametro.$1, style: fila),
                                Text(parametro.$2, style: fila),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ItemListaCampo(
                    titulo: 'Trabajo abierto 05:24',
                    subtitulo: 'trabajo · local · pendiente de sync',
                    icono: Icons.flight_takeoff,
                    valor: 'PEND',
                  ),
                  const SizedBox(height: 10),
                  const ItemListaCampo(
                    titulo: 'Sesión 1 · en ejecución',
                    subtitulo: 'sesion · piloto Rubén · dron T50 #2',
                    icono: Icons.play_arrow,
                    colorIcono: ColoresCampo.acentoAmbar,
                    valor: 'PEND',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: BotonPrimarioCampo(
                texto: 'Abrir trabajo',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
