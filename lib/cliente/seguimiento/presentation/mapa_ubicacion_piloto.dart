import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/mapa_lote.dart';
import '../../../nucleo/ui/paleta_campo.dart';

LatLng _ll(GeoPunto p) => LatLng(p.latitud, p.longitud);

/// El lote y un solo punto: la última ubicación que reportó la app del
/// piloto. No hay ruta, estela ni tiempo estimado (ADR 0017). Con [punto]
/// nulo muestra solo el lote; con [vigente] en falso, el punto se atenúa
/// para que no parezca una posición actual.
class MapaUbicacionPiloto extends StatelessWidget {
  const MapaUbicacionPiloto({
    required this.lote,
    this.punto,
    this.vigente = true,
    this.conTeselas,
    super.key,
  });

  final Lote lote;
  final GeoPunto? punto;
  final bool vigente;

  /// Por defecto, [ConfiguracionMapa.teselas].
  final bool? conTeselas;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final teselas = conTeselas ?? ConfiguracionMapa.teselas;
    final puntos = [
      for (final p in lote.poligono) _ll(p),
      if (punto != null) _ll(punto!),
    ];
    final color = vigente ? paleta.acento : paleta.textoSecundario;
    return Semantics(
      label: punto == null
          ? 'Mapa del lote ${lote.nombre}, sin ubicación del piloto'
          : 'Mapa del lote ${lote.nombre} con la última ubicación del piloto',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FlutterMap(
          options: MapOptions(
            backgroundColor: ConfiguracionMapa.fondo(paleta),
            initialCameraFit: CameraFit.coordinates(
              coordinates: puntos,
              padding: const EdgeInsets.all(48),
              maxZoom: 16.5,
            ),
            // Un vistazo, no un mapa para explorar: así un dedo sobre él sigue
            // desplazando la pantalla en vez de mover el mapa.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            if (teselas)
              TileLayer(
                urlTemplate: ConfiguracionMapa.urlTeselas,
                userAgentPackageName: ConfiguracionMapa.agenteUsuario,
              ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: [for (final p in lote.poligono) _ll(p)],
                  color: paleta.acento.withValues(alpha: 0.28),
                  borderColor: paleta.acentoTexto,
                  borderStrokeWidth: 2.5,
                ),
              ],
            ),
            if (punto != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _ll(punto!),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: paleta.sobreAcento, width: 2),
                        boxShadow: const [
                          BoxShadow(blurRadius: 8, color: Color(0x55000000)),
                        ],
                      ),
                      child: Icon(
                        Icons.person_pin_circle_rounded,
                        color: paleta.sobreAcento,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            if (teselas)
              MediaQuery.withNoTextScaling(
                child: const SimpleAttributionWidget(
                  source: Text('OpenStreetMap'),
                  backgroundColor: Color(0xCCFFFFFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
