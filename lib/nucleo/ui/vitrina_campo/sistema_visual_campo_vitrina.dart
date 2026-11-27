import 'package:flutter/material.dart';

import '../componentes/componentes_campo.dart';
import '../paleta_campo.dart';
import '../tema_campo.dart';
import '../tokens_campo.dart';

/// Vitrina del sistema visual del marketplace: paleta, tipografía y los
/// componentes de marketplace (oferta entrante, calificación, esqueleto)
/// en los tres modos. Datos constantes, como el resto de la vitrina.
class SistemaVisualCampoVitrina extends StatefulWidget {
  const SistemaVisualCampoVitrina({super.key});

  @override
  State<SistemaVisualCampoVitrina> createState() =>
      _SistemaVisualCampoVitrinaState();
}

class _SistemaVisualCampoVitrinaState extends State<SistemaVisualCampoVitrina> {
  ModoVisualCampo _modo = ModoVisualCampo.claro;
  int _calificacion = 4;

  static const _opciones = [
    (ModoVisualCampo.claro, 'Claro'),
    (ModoVisualCampo.oscuro, 'Campo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(modo: _modo),
      child: Builder(
        builder: (context) {
          final paleta = context.paleta;
          final texto = Theme.of(context).textTheme;
          return ColoredBox(
            color: paleta.fondo,
            child: ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              children: [
                SegmentedButton<ModoVisualCampo>(
                  segments: [
                    for (final (modo, etiqueta) in _opciones)
                      ButtonSegment(value: modo, label: Text(etiqueta)),
                  ],
                  selected: {_modo},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: paleta.texto,
                    selectedBackgroundColor: paleta.acento,
                    selectedForegroundColor: paleta.sobreAcento,
                    side: BorderSide(color: paleta.bordeFuerte),
                    minimumSize: const Size(0, ObjetivoTactilCampo.minimo),
                  ),
                  onSelectionChanged: (m) => setState(() => _modo = m.first),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                Text('Sistema visual', style: texto.headlineMedium),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  'Roles de color, tipografía y componentes del marketplace.',
                  style: texto.bodyMedium,
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Seccion(titulo: 'PALETA', paleta: paleta),
                Wrap(
                  spacing: EspaciadoCampo.s,
                  runSpacing: EspaciadoCampo.s,
                  children: [
                    _Muestra('fondo', paleta.fondo, paleta),
                    _Muestra('superficie', paleta.superficie, paleta),
                    _Muestra('elevada', paleta.superficieElevada, paleta),
                    _Muestra('acento', paleta.acento, paleta),
                    _Muestra('éxito', paleta.exito, paleta),
                    _Muestra('alerta', paleta.alerta, paleta),
                    _Muestra('error', paleta.error, paleta),
                    _Muestra('info', paleta.info, paleta),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Seccion(titulo: 'TIPOGRAFÍA', paleta: paleta),
                Text('Hectáreas cubiertas', style: texto.titleLarge),
                const SizedBox(height: EspaciadoCampo.xs),
                Text('42,5 ha', style: texto.headlineSmall),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  'Texto de lectura con contraste verificado.',
                  style: texto.bodyLarge,
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Seccion(titulo: 'OFERTA ENTRANTE', paleta: paleta),
                OfertaServicioCampo(
                  titulo: 'Soja · 42 ha',
                  detalle: 'Lote 14, a 12 km de tu base',
                  distancia: '12 km',
                  monto: 'Bs 3.150',
                  restante: const Duration(seconds: 47),
                  total: const Duration(seconds: 90),
                  onAceptar: () {},
                  onRechazar: () {},
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Seccion(titulo: 'CALIFICACIÓN', paleta: paleta),
                CalificacionCampo(
                  valor: _calificacion,
                  onCambio: (v) => setState(() => _calificacion = v),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Seccion(titulo: 'CARGANDO', paleta: paleta),
                Container(
                  padding: const EdgeInsets.all(EspaciadoCampo.l),
                  decoration: BoxDecoration(
                    color: paleta.superficie,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: paleta.borde),
                  ),
                  child: Row(
                    children: [
                      const EsqueletoCampo(ancho: 48, alto: 48, radio: 24),
                      const SizedBox(width: EspaciadoCampo.m),
                      Expanded(child: EsqueletoCampo.texto(lineas: 2)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.paleta});

  final String titulo;
  final PaletaCampo paleta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
      child: Text(titulo, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra(this.nombre, this.color, this.paleta);

  final String nombre;
  final Color color;
  final PaletaCampo paleta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: paleta.bordeFuerte),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(nombre, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
