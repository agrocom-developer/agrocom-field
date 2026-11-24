import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import 'solicitar_estado.dart';

LatLng _ll(GeoPunto p) => LatLng(p.latitud, p.longitud);
GeoPunto _geo(LatLng p) => GeoPunto(p.latitude, p.longitude);

/// Centro de la zona agrícola de Santa Cruz: donde abre el mapa cuando el
/// cliente todavía no tiene lotes ni marcó ninguna esquina.
const _centroPorDefecto = LatLng(-17.2, -62.65);

/// Mapa del paso «Lote»: muestra los lotes guardados para elegir uno con un
/// toque, o deja dibujar un contorno tocando las esquinas. Cada esquina se
/// puede arrastrar. La superficie se muestra en grande sobre el mapa.
class MapaSolicitud extends StatefulWidget {
  const MapaSolicitud({
    required this.lotes,
    required this.modo,
    this.seleccionado,
    this.vertices = const [],
    this.superficie,
    this.editable = true,
    this.alSeleccionar,
    this.alAgregarVertice,
    this.alMoverVertice,
    super.key,
  });

  final List<Lote> lotes;
  final ModoLote modo;
  final Lote? seleccionado;
  final List<GeoPunto> vertices;

  /// Superficie ya formateada («85,5 ha») para la insignia del mapa.
  final String? superficie;

  /// Con `false` el mapa solo muestra: ni se mueve ni recibe toques.
  final bool editable;
  final ValueChanged<Lote>? alSeleccionar;
  final ValueChanged<GeoPunto>? alAgregarVertice;
  final void Function(int indice, GeoPunto punto)? alMoverVertice;

  @override
  State<MapaSolicitud> createState() => _MapaSolicitudState();
}

class _MapaSolicitudState extends State<MapaSolicitud>
    with SingleTickerProviderStateMixin {
  final _controlador = MapController();
  final _claveMapa = GlobalKey();
  late final AnimationController _vuelo = AnimationController(
    vsync: this,
    duration: MovimientoCampo.lenta,
  );
  LatLngTween? _centro;
  Tween<double>? _zoom;

  static const _relleno = EdgeInsets.fromLTRB(40, 72, 40, 40);

  @override
  void initState() {
    super.initState();
    _vuelo.addListener(_avanzarVuelo);
  }

  @override
  void didUpdateWidget(MapaSolicitud anterior) {
    super.didUpdateWidget(anterior);
    final cambioLote = widget.seleccionado?.id != anterior.seleccionado?.id;
    final cambioModo = widget.modo != anterior.modo;
    if (widget.modo == ModoLote.guardado && (cambioLote || cambioModo)) {
      final puntos = _puntosDeEncuadre();
      if (puntos.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _encuadrar(puntos);
        });
      }
    }
  }

  @override
  void dispose() {
    _vuelo.dispose();
    _controlador.dispose();
    super.dispose();
  }

  /// Lo que tiene que quedar a la vista: el lote elegido, el contorno en
  /// curso o, si no hay ninguno, todos los lotes del cliente.
  List<GeoPunto> _puntosDeEncuadre() {
    if (widget.modo == ModoLote.dibujo && widget.vertices.isNotEmpty) {
      return widget.vertices;
    }
    final elegido = widget.seleccionado;
    if (widget.modo == ModoLote.guardado && elegido != null) {
      return elegido.poligono;
    }
    return [for (final l in widget.lotes) ...l.poligono];
  }

  CameraFit _ajuste(List<GeoPunto> puntos) => CameraFit.coordinates(
    coordinates: [for (final p in puntos) _ll(p)],
    padding: _relleno,
    maxZoom: 16.5,
  );

  /// Lleva la cámara al encuadre nuevo. El desplazamiento explica qué lote
  /// quedó elegido; con movimiento reducido el cambio es instantáneo.
  void _encuadrar(List<GeoPunto> puntos) {
    final camara = _controlador.camera;
    final destino = _ajuste(puntos).fit(camara);
    if (MovimientoCampo.reducido(context)) {
      _controlador.move(destino.center, destino.zoom);
      return;
    }
    _centro = LatLngTween(begin: camara.center, end: destino.center);
    _zoom = Tween(begin: camara.zoom, end: destino.zoom);
    _vuelo.forward(from: 0);
  }

  void _avanzarVuelo() {
    final centro = _centro;
    final zoom = _zoom;
    if (centro == null || zoom == null) return;
    final t = MovimientoCampo.movimiento.transform(_vuelo.value);
    _controlador.move(centro.transform(t), zoom.transform(t));
  }

  void _alTocar(LatLng punto) {
    final geo = _geo(punto);
    if (widget.modo == ModoLote.dibujo) {
      HapticaCampo.seleccion();
      widget.alAgregarVertice?.call(geo);
      return;
    }
    for (final lote in widget.lotes) {
      if (poligonoContiene(lote.poligono, geo)) {
        HapticaCampo.seleccion();
        widget.alSeleccionar?.call(lote);
        return;
      }
    }
  }

  void _alArrastrar(int indice, Offset posicionGlobal) {
    final caja = _claveMapa.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null) return;
    final local = caja.globalToLocal(posicionGlobal);
    widget.alMoverVertice?.call(
      indice,
      _geo(_controlador.camera.screenOffsetToLatLng(local)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final dibujo = widget.modo == ModoLote.dibujo;
    final teselas = ConfiguracionMapa.teselas;
    final puntosIniciales = _puntosDeEncuadre();
    final elegido = dibujo ? null : widget.seleccionado;

    // El doble toque para acercar retrasa 250 ms cada toque simple. Aquí un
    // toque elige un lote o marca una esquina y tiene que responder al
    // instante; para acercar queda el gesto de pellizco.
    const gestos =
        InteractiveFlag.all &
        ~InteractiveFlag.rotate &
        ~InteractiveFlag.doubleTapZoom &
        ~InteractiveFlag.doubleTapDragZoom;

    return Semantics(
      container: true,
      label: dibujo
          ? 'Mapa para dibujar el contorno del lote. '
                '${widget.vertices.length} esquinas marcadas.'
          : elegido != null
          ? 'Mapa. Lote elegido: ${elegido.nombre}, ${elegido.zona}.'
          : 'Mapa de tus lotes. Toca uno para elegirlo.',
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FlutterMap(
              key: _claveMapa,
              mapController: _controlador,
              options: MapOptions(
                backgroundColor: ConfiguracionMapa.fondo(paleta),
                initialCenter: _centroPorDefecto,
                initialZoom: 9,
                initialCameraFit: puntosIniciales.length > 1
                    ? _ajuste(puntosIniciales)
                    : null,
                interactionOptions: InteractionOptions(
                  flags: widget.editable ? gestos : InteractiveFlag.none,
                ),
                onTap: widget.editable ? (_, punto) => _alTocar(punto) : null,
              ),
              children: [
                if (teselas)
                  TileLayer(
                    urlTemplate: ConfiguracionMapa.urlTeselas,
                    userAgentPackageName: ConfiguracionMapa.agenteUsuario,
                  ),
                PolygonLayer(
                  polygons: [
                    for (final l in widget.lotes)
                      _poligonoGuardado(
                        l,
                        paleta,
                        elegido: l.id == elegido?.id,
                        atenuado: dibujo || elegido != null,
                      ),
                    if (dibujo && widget.vertices.length >= 3)
                      Polygon(
                        points: [for (final p in widget.vertices) _ll(p)],
                        color: paleta.acento.withValues(alpha: 0.38),
                        borderColor: paleta.acentoTexto,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
                if (dibujo && widget.vertices.length == 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [for (final p in widget.vertices) _ll(p)],
                        strokeWidth: 3,
                        color: paleta.acentoTexto,
                      ),
                    ],
                  ),
                if (dibujo)
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < widget.vertices.length; i++)
                        Marker(
                          key: ValueKey('marcador-vertice-$i'),
                          point: _ll(widget.vertices[i]),
                          width: ObjetivoTactilCampo.guantes,
                          height: ObjetivoTactilCampo.guantes,
                          child: _Vertice(
                            key: ValueKey('vertice-$i'),
                            numero: i + 1,
                            arrastrable: widget.editable,
                            alArrastrar: (posicion) =>
                                _alArrastrar(i, posicion),
                          ),
                        ),
                    ],
                  ),
                if (teselas)
                  SimpleAttributionWidget(
                    source: const Text('OpenStreetMap'),
                    backgroundColor: paleta.superficie.withValues(alpha: 0.8),
                  ),
              ],
            ),
          ),
          if (widget.superficie != null)
            Positioned(
              top: EspaciadoCampo.m,
              left: EspaciadoCampo.m,
              right: EspaciadoCampo.m,
              child: Align(
                alignment: Alignment.topLeft,
                child: _InsigniaSuperficie(widget.superficie!),
              ),
            ),
        ],
      ),
    );
  }

  Polygon _poligonoGuardado(
    Lote lote,
    PaletaCampo paleta, {
    required bool elegido,
    required bool atenuado,
  }) {
    final apagado = atenuado && !elegido;
    return Polygon(
      points: [for (final p in lote.poligono) _ll(p)],
      color: (apagado ? paleta.textoSecundario : paleta.acento).withValues(
        alpha: elegido ? 0.38 : 0.2,
      ),
      borderColor: apagado ? paleta.textoSecundario : paleta.acentoTexto,
      borderStrokeWidth: elegido ? 3 : 2,
    );
  }
}

/// Superficie del lote, en grande, sobre el mapa.
class _InsigniaSuperficie extends StatelessWidget {
  const _InsigniaSuperficie(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      liveRegion: true,
      label: 'Superficie: $texto',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
          child: Container(
            key: ValueKey(texto),
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.l,
              vertical: EspaciadoCampo.s,
            ),
            decoration: BoxDecoration(
              color: paleta.superficie,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: paleta.borde),
              boxShadow: ElevacionCampo.sombras(paleta, 2),
            ),
            // El dato ya es grande: con el texto muy ampliado no crece más,
            // para no tapar el lote que describe.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  texto,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Esquina del contorno. El punto visible es chico, pero el área que
/// responde al dedo ocupa todo el marcador.
class _Vertice extends StatelessWidget {
  const _Vertice({
    required this.numero,
    required this.arrastrable,
    required this.alArrastrar,
    super.key,
  });

  final int numero;
  final bool arrastrable;
  final ValueChanged<Offset> alArrastrar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final punto = Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: numero == 1 ? paleta.acento : paleta.superficie,
          shape: BoxShape.circle,
          border: Border.all(color: paleta.acentoTexto, width: 3),
          boxShadow: ElevacionCampo.sombras(paleta, 1),
        ),
      ),
    );
    return Semantics(
      label: 'Esquina $numero del lote',
      hint: arrastrable ? 'Arrastra para moverla' : null,
      child: !arrastrable
          ? punto
          : RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                _ArrastreInmediato:
                    GestureRecognizerFactoryWithHandlers<_ArrastreInmediato>(
                      _ArrastreInmediato.new,
                      (r) => r
                        ..onStart = ((_) => HapticaCampo.seleccion())
                        ..onUpdate = (d) => alArrastrar(d.globalPosition),
                    ),
              },
              child: punto,
            ),
    );
  }
}

/// Arrastre que gana el gesto en cuanto el dedo toca la esquina: si
/// compitiera con el desplazamiento del mapa, se movería el mapa y no el
/// punto.
class _ArrastreInmediato extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
