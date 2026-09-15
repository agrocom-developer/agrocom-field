import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../tipografia_campo.dart';

enum _TipoInsumoVitrina { liquido, solido }

/// 04 · Crear aplicación (HU-79) — alterna líquido/sólido para mostrar cómo
/// cambian los campos según `tipo_insumo`. Recreada del mockup de
/// referencia (ADR 0008); pH de la calda y litros/ha son datos mock — el
/// ADR aclara que ese mockup no es la especificación real de `agrocom-api`.
class CrearAplicacionCampoVitrina extends StatefulWidget {
  const CrearAplicacionCampoVitrina({super.key});

  @override
  State<CrearAplicacionCampoVitrina> createState() =>
      _CrearAplicacionCampoVitrinaState();
}

class _CrearAplicacionCampoVitrinaState
    extends State<CrearAplicacionCampoVitrina> {
  _TipoInsumoVitrina _tipo = _TipoInsumoVitrina.liquido;

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
              subtitulo: 'Lote 14 · 42,5 ha',
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
                  'tipo_insumo viene de la orden (HU-79). Editable solo si '
                  'el servidor no lo trae.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (esLiquido) ...[
                    const StatChipCampo(
                      etiqueta: 'Litros por hectárea',
                      valor: '12',
                      unidad: 'L/ha',
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: StatChipCampo(
                            etiqueta: 'Ph agua',
                            valor: '7,4',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatChipCampo(
                            etiqueta: 'Ph de la calda',
                            valor: '5,8',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const StatChipCampo(
                      etiqueta: 'Kilos por vuelo',
                      valor: '38',
                      unidad: 'kg',
                    ),
                    const SizedBox(height: 12),
                    const NotaTecnicaCampo(
                      texto:
                          'Ph agua, Ph de la calda y litros/ha no se piden '
                          'en sólido.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  TarjetaCampo(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mezcla del caldo',
                              style: TipografiaCampo.tituloTarjeta,
                            ),
                            Text(
                              '3 productos →',
                              style: TipografiaCampo.datoMonoDestacado,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final producto in const [
                          ('Glifosato', '3,0 L'),
                          ('24D', '0,8 L'),
                          ('Agua', '510 L'),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(producto.$1, style: fila),
                                Text(producto.$2, style: fila),
                              ],
                            ),
                          ),
                      ],
                    ),
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
