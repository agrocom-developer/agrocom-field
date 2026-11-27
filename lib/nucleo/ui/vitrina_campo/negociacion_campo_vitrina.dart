import 'package:flutter/material.dart';

import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../paleta_campo.dart';
import '../tema_campo.dart';
import '../tokens_campo.dart';

/// Vitrina de los componentes de negociación y de la paleta Industrial
/// AgTech: burbujas de ronda, ticket de pedido, post-it, collage de fotos,
/// banner sin señal, stepper ±1 y hoja inferior. Datos constantes.
///
/// Con [modo] fijo (goldens) no muestra el selector de modo.
class NegociacionCampoVitrina extends StatefulWidget {
  const NegociacionCampoVitrina({this.modo, super.key});

  final ModoVisualCampo? modo;

  @override
  State<NegociacionCampoVitrina> createState() =>
      _NegociacionCampoVitrinaState();
}

class _NegociacionCampoVitrinaState extends State<NegociacionCampoVitrina> {
  ModoVisualCampo _modo = ModoVisualCampo.claro;
  int _ronda = 3;

  @override
  Widget build(BuildContext context) {
    final modo = widget.modo ?? _modo;
    return Theme(
      data: AgrocomThemeCampo.construir(modo: modo),
      child: Builder(
        builder: (context) {
          final paleta = context.paleta;
          final texto = Theme.of(context).textTheme;
          return ColoredBox(
            color: paleta.fondo,
            child: ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              children: [
                if (widget.modo == null) ...[
                  SegmentedButton<ModoVisualCampo>(
                    segments: const [
                      ButtonSegment(
                        value: ModoVisualCampo.claro,
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ModoVisualCampo.campo,
                        label: Text('Campo'),
                      ),
                    ],
                    selected: {_modo},
                    showSelectedIcon: false,
                    onSelectionChanged: (m) => setState(() => _modo = m.first),
                  ),
                  const SizedBox(height: EspaciadoCampo.xl),
                ],
                const BannerSinSenalCampo(
                  mensaje: 'tu oferta se guarda y sale al volver.',
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('COLORES DE MARCA', texto),
                Wrap(
                  spacing: EspaciadoCampo.s,
                  runSpacing: EspaciadoCampo.s,
                  children: [
                    _Muestra('acento', paleta.acento, paleta),
                    _Muestra('grafito', paleta.grafito, paleta),
                    _Muestra('ámbar', paleta.ambar, paleta),
                    _Muestra('papel', paleta.papel, paleta),
                    _Muestra('info', paleta.rellenoInfo, paleta),
                    _Muestra('error', paleta.rellenoError, paleta),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('NEGOCIACIÓN', texto),
                const BurbujaNegociacionCampo(
                  autor: AutorRonda.cliente,
                  ronda: 1,
                  precioPorHectarea: '80',
                  total: '7.200',
                ),
                const SizedBox(height: EspaciadoCampo.m),
                const BurbujaNegociacionCampo(
                  autor: AutorRonda.piloto,
                  ronda: 2,
                  precioPorHectarea: '95',
                  total: '8.550',
                ),
                const SizedBox(height: EspaciadoCampo.m),
                const BurbujaNegociacionCampo(
                  autor: AutorRonda.cliente,
                  ronda: 3,
                  precioPorHectarea: '85',
                  total: '7.650',
                  esTurno: true,
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('TICKET DE PEDIDO', texto),
                const TicketPedidoCampo(
                  numero: '#0412',
                  estado: 'En negociación',
                  filas: [
                    FilaTicketCampo(clave: 'Lote', valor: 'La Nena · Soja'),
                    FilaTicketCampo(
                      clave: 'Superficie',
                      valor: '90',
                      unidad: 'ha',
                      esCifra: true,
                    ),
                    FilaTicketCampo(
                      clave: 'Precio',
                      valor: '85',
                      unidad: 'Bs/ha',
                      esCifra: true,
                    ),
                  ],
                  total: '7.650',
                  etiquetaTotal: 'Total acordado',
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('POST-IT DE OFERTA', texto),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PostItOfertaCampo(
                        piloto: 'Rubén M.',
                        detalle: '4,9 de 5 · 12 km',
                        precioPorHectarea: '85',
                        total: '7.650',
                        elegido: true,
                      ),
                    ),
                    SizedBox(width: EspaciadoCampo.l),
                    Expanded(
                      child: PostItOfertaCampo(
                        piloto: 'Ana C.',
                        detalle: '4,7 de 5 · 20 km',
                        precioPorHectarea: '90',
                        total: '8.100',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('AVANCE CON FOTOS', texto),
                CollageFotosCampo(
                  principal: FotoCollageCampo(
                    imagen: Image.asset(
                      ImagenesCampo.dronPulverizando,
                      fit: BoxFit.cover,
                    ),
                    hora: '14:32',
                    descripcion: 'Dron fumigando el lote',
                  ),
                  secundaria: FotoCollageCampo(
                    imagen: Image.asset(
                      ImagenesCampo.dronSobreAgua,
                      fit: BoxFit.cover,
                    ),
                    hora: '14:05',
                    descripcion: 'Carga del tanque',
                  ),
                  valorDato: '38,5',
                  unidadDato: 'ha',
                  etiquetaDato: 'Avance',
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('STEPPER ±1', texto),
                Center(
                  child: StepperCampo(
                    valor: _ronda,
                    minimo: 1,
                    maximo: 5,
                    unidad: 'de 5 rondas',
                    etiqueta: 'Ronda',
                    alturaCampo: modo == ModoVisualCampo.campo,
                    onCambio: (v) => setState(() => _ronda = v),
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                _Titulo('HOJA INFERIOR', texto),
                HojaInferiorCampo(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lote La Nena', style: texto.headlineSmall),
                      const SizedBox(height: EspaciadoCampo.xs),
                      Text(
                        '3 ofertas · la mejor, Bs 85/ha',
                        style: texto.bodyMedium,
                      ),
                      const SizedBox(height: EspaciadoCampo.l),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Ver ofertas'),
                      ),
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

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, this.tema);

  final String texto;
  final TextTheme tema;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
    child: Text(texto, style: tema.labelSmall),
  );
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
            borderRadius: BorderRadius.circular(RadioCampo.chip),
            border: Border.all(color: paleta.bordeFuerte),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(nombre, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
