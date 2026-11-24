import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../ui/paleta_campo.dart';
import '../../../ui/formato_marketplace.dart';
import '../../../ui/mapa_lote.dart';
import '../domain/negociacion.dart';

/// Centro de Santa Cruz de la Sierra, para cuando todavía no hay solicitudes.
const _centroSantaCruz = LatLng(-17.7833, -63.1821);

/// Mapa con un marcador por solicitud abierta, con el precio por hectárea
/// propuesto. Un marcador no se comunica solo con color: lleva el precio
/// escrito y el seleccionado se engrosa.
class MapaSolicitudes extends StatelessWidget {
  const MapaSolicitudes({
    required this.solicitudes,
    required this.alSeleccionar,
    this.seleccionada,
    this.conTeselas,
    super.key,
  });

  final List<SolicitudAbierta> solicitudes;
  final int? seleccionada;
  final ValueChanged<SolicitudAbierta> alSeleccionar;
  final bool? conTeselas;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final teselas = conTeselas ?? ConfiguracionMapa.teselas;
    final ubicadas = [
      for (final s in solicitudes)
        if (s.ubicacion != null) s,
    ];
    final puntos = [
      for (final s in ubicadas)
        LatLng(s.ubicacion!.latitud, s.ubicacion!.longitud),
    ];
    return Semantics(
      label:
          'Mapa de solicitudes abiertas, ${ubicadas.length} '
          '${ubicadas.length == 1 ? 'solicitud' : 'solicitudes'}',
      child: ClipRect(
        child: FlutterMap(
          options: MapOptions(
            backgroundColor: ConfiguracionMapa.fondo(paleta),
            initialCenter: _centroSantaCruz,
            initialZoom: 6.2,
            initialCameraFit: puntos.length >= 2
                ? CameraFit.coordinates(
                    coordinates: puntos,
                    padding: const EdgeInsets.all(48),
                    maxZoom: 11,
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (teselas)
              TileLayer(
                urlTemplate: ConfiguracionMapa.urlTeselas,
                userAgentPackageName: ConfiguracionMapa.agenteUsuario,
              ),
            MarkerLayer(
              markers: [
                for (final s in ubicadas)
                  Marker(
                    point: LatLng(s.ubicacion!.latitud, s.ubicacion!.longitud),
                    width: 124,
                    height: 48,
                    child: _Marcador(
                      solicitud: s,
                      activo: s.id == seleccionada,
                      alToque: () => alSeleccionar(s),
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

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.solicitud,
    required this.activo,
    required this.alToque,
  });

  final SolicitudAbierta solicitud;
  final bool activo;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final propia = solicitud.miNegociacion == MiNegociacion.vigente;
    // Los marcadores son la vista visual de la lista de abajo; quien usa un
    // lector de pantalla recorre las tarjetas, que dicen lo mismo y abren el
    // mismo detalle. Por eso no se anuncian dos veces.
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: alToque,
        behavior: HitTestBehavior.opaque,
        child: MediaQuery.withNoTextScaling(
          // El objetivo táctil mide el alto del marcador (48): más que la
          // pastilla que se dibuja.
          child: SizedBox.expand(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: activo ? paleta.acento : paleta.superficie,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activo ? paleta.acentoTexto : paleta.borde,
                    width: activo ? 3 : 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Color(0x44000000)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (propia) ...[
                      Icon(
                        Icons.handshake_rounded,
                        size: 14,
                        color: activo ? paleta.sobreAcento : paleta.acentoTexto,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      FormatoMarketplace.bs(solicitud.precioHaPropuesto),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activo ? paleta.sobreAcento : paleta.texto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
