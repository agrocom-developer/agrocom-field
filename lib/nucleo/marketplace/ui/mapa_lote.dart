import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/colores_campo.dart';
import '../../ui/paleta_campo.dart';
import '../dominio/dominio.dart';
import '../../../l10n/app_localizations.dart';

LatLng _ll(GeoPunto p) => LatLng(p.latitud, p.longitud);

/// Interruptor global de las teselas de red. Los tests y las capturas lo
/// apagan para no depender de la red.
abstract final class ConfiguracionMapa {
  static bool teselas = true;

  static const urlTeselas = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const agenteUsuario = 'com.agrocom.agrocom_field';

  /// Velo `map-dim` que va sobre las teselas, según el modo de la paleta.
  static Color velo(PaletaCampo paleta) => paleta.esCampo
      ? ColoresCampo.veloMapaCampo
      : paleta.brillo == Brightness.dark
      ? ColoresCampo.veloMapaOscuro
      : ColoresCampo.veloMapaClaro;

  /// Color del mapa sin teselas (sin red o mientras cargan).
  static Color fondo(PaletaCampo paleta) => paleta.brillo == Brightness.dark
      ? ColoresCampo.mapaVacioOscuro
      : ColoresCampo.mapaVacioClaro;
}

/// Mapa con el contorno de uno o más lotes, la estela del dron y su posición.
/// Teselas abiertas de OpenStreetMap (ADR 0009 de decisiones de UI: sin clave
/// de proveedor). Con [conTeselas] en falso solo dibuja los polígonos sobre el
/// fondo, que es lo que ve un lote sin señal y lo que usan los tests.
class MapaLote extends StatelessWidget {
  const MapaLote({
    required this.lotes,
    this.seleccionado,
    this.posicionDron,
    this.trazado = const [],
    this.interactivo = true,
    this.conTeselas,
    this.alSeleccionar,
    this.relleno = const EdgeInsets.all(40),
    super.key,
  });

  final List<Lote> lotes;

  /// Lote resaltado con el acento; el resto se dibuja atenuado.
  final Lote? seleccionado;
  final GeoPunto? posicionDron;
  final List<GeoPunto> trazado;
  final bool interactivo;

  /// Por defecto, [ConfiguracionMapa.teselas].
  final bool? conTeselas;
  final ValueChanged<Lote>? alSeleccionar;
  final EdgeInsets relleno;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final teselas = conTeselas ?? ConfiguracionMapa.teselas;
    final puntos = [
      for (final l in (seleccionado != null ? [seleccionado!] : lotes))
        ...l.poligono,
      ?posicionDron,
    ];
    final fondo = ConfiguracionMapa.fondo(paleta);
    return Semantics(
      label: seleccionado != null
          ? l10n.uiMapaDelLote(seleccionado!.nombre, seleccionado!.zona)
          : l10n.uiMapaLotes,
      child: ClipRect(
        child: FlutterMap(
          options: MapOptions(
            backgroundColor: fondo,
            initialCameraFit: CameraFit.coordinates(
              coordinates: [for (final p in puntos) _ll(p)],
              padding: relleno,
              maxZoom: 16.5,
            ),
            interactionOptions: InteractionOptions(
              flags: interactivo
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onTap: (_, punto) {
              if (alSeleccionar == null) return;
              for (final l in lotes) {
                if (poligonoContiene(
                  l.poligono,
                  GeoPunto(punto.latitude, punto.longitude),
                )) {
                  alSeleccionar!(l);
                  return;
                }
              }
            },
          ),
          children: [
            if (teselas)
              TileLayer(
                urlTemplate: ConfiguracionMapa.urlTeselas,
                userAgentPackageName: ConfiguracionMapa.agenteUsuario,
              ),
            PolygonLayer(
              polygons: [
                for (final l in lotes)
                  Polygon(
                    points: [for (final p in l.poligono) _ll(p)],
                    color:
                        (l.id == seleccionado?.id || seleccionado == null
                                ? paleta.acento
                                : paleta.textoSecundario)
                            .withValues(
                              alpha: l.id == seleccionado?.id ? 0.38 : 0.2,
                            ),
                    borderColor:
                        l.id == seleccionado?.id || seleccionado == null
                        ? paleta.acentoTexto
                        : paleta.textoSecundario,
                    borderStrokeWidth: l.id == seleccionado?.id ? 3 : 2,
                  ),
              ],
            ),
            if (trazado.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [for (final p in trazado) _ll(p)],
                    strokeWidth: 3,
                    color: paleta.info,
                  ),
                ],
              ),
            if (posicionDron != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _ll(posicionDron!),
                    width: 44,
                    height: 44,
                    child: Semantics(
                      label: l10n.uiPosicionDelDron,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paleta.acento,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: paleta.sobreAcento,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 8,
                              color: ColoresCampo.sombraMapa,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flight_rounded,
                          color: paleta.sobreAcento,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (teselas)
              // La atribución legal no escala con el texto del sistema: a
              // 200 % su fila se salía del mapa.
              MediaQuery.withNoTextScaling(
                child: SimpleAttributionWidget(
                  source: Text(l10n.uiOpenstreetmap),
                  backgroundColor: ColoresCampo.atribucionMapa,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
