import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../tipografia_campo.dart';

enum _TipoInsumoVitrina { liquido, solido }

/// 04 · Crear aplicación = abrir trabajo (HU-05) sobre una orden del
/// catálogo, ajustada al contrato real (`docs/api/openapi.yaml` de
/// `agrocom-api`): la orden trae `litros_ha` (líquido) O `kilos_por_vuelo`
/// (sólido), nunca los dos (HU-79, tarea 110), y `lotes[]` con las
/// hectáreas solicitadas por lote (HU-92); el trabajo declara `orden_id`,
/// `lote_id`, `nro_aplicacion` y `hectareas_declaradas`.
///
/// El selector líquido/sólido es solo para ver las dos variantes — en la
/// pantalla real lo decide la orden. Lo que el mockup traía y ningún
/// esquema tiene: pH del agua y de la calda (no existen en el contrato). La
/// mezcla del caldo queda fuera de la vista previa por pedido del dueño
/// (14/9/2026). Datos mock.
class CrearAplicacionCampoVitrina extends StatefulWidget {
  const CrearAplicacionCampoVitrina({super.key});

  @override
  State<CrearAplicacionCampoVitrina> createState() =>
      _CrearAplicacionCampoVitrinaState();
}

class _CrearAplicacionCampoVitrinaState
    extends State<CrearAplicacionCampoVitrina> {
  _TipoInsumoVitrina _tipo = _TipoInsumoVitrina.liquido;
  final _hectareas = TextEditingController(text: '42,5');

  @override
  void dispose() {
    _hectareas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esLiquido = _tipo == _TipoInsumoVitrina.liquido;
    final fila = TipografiaCampo.datoMono.copyWith(
      fontSize: 13,
      color: ColoresCampo.textoPrincipal.withValues(
        alpha: OpacidadesCampo.media,
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoCampo(
              titulo: 'Nueva aplicación',
              subtitulo: 'Orden 2431 · aplicación N.º 3',
            ),
            const SizedBox(height: 16),
            SelectorSegmentadoCampo<_TipoInsumoVitrina>(
              opciones: const [
                (_TipoInsumoVitrina.liquido, 'Líquido'),
                (_TipoInsumoVitrina.solido, 'Sólido'),
              ],
              seleccionado: _tipo,
              onSeleccionar: (valor) => setState(() => _tipo = valor),
            ),
            const SizedBox(height: 10),
            const NotaTecnicaCampo(
              texto:
                  'La orden trae litros_ha o kilos_por_vuelo (HU-79), nunca '
                  'los dos: en la pantalla real no se elige, se muestra el '
                  'que viene. El selector es solo para ver ambas variantes.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (esLiquido)
                    const StatChipCampo(
                      etiqueta: 'Litros por hectárea',
                      valor: '12',
                      unidad: 'L/ha',
                    )
                  else
                    const StatChipCampo(
                      etiqueta: 'Kilos por vuelo',
                      valor: '38',
                      unidad: 'kg',
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
                              'Lote del trabajo',
                              style: TipografiaCampo.tituloTarjeta,
                            ),
                            Text(
                              '2 lotes en la orden',
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
                  CampoTextoCampo(
                    etiqueta: 'Hectáreas declaradas',
                    controller: _hectareas,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const NotaTecnicaCampo(
                    texto:
                        'trabajo · uuid_cliente generado acá · orden_id + '
                        'lote_id + nro_aplicacion + hectareas_declaradas. '
                        'Nunca en double (invariante 9).',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const NotaInlineCampo(
              texto: 'Se guarda local y queda pendiente de sync',
            ),
            const SizedBox(height: 12),
            BotonPrimarioCampo(texto: 'Guardar aplicación', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
