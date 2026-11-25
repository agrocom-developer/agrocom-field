import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/colores_campo.dart';
import '../../../../ui/componentes/cifra_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tipografia_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/formato_marketplace.dart';
import '../../../ui/mapa_lote.dart';
import '../domain/negociacion.dart';
import 'cifras_negociacion.dart';

/// Centro de Santa Cruz de la Sierra, para cuando todavía no hay solicitudes.
const _centroSantaCruz = LatLng(-17.7833, -63.1821);

/// ¿La solicitud deja de recibir ofertas hoy? Compara el día calendario de
/// `vence_en` con el de [ahora] (el reloj lo inyecta quien llama).
bool venceHoy(SolicitudAbierta s, DateTime ahora) {
  final v = s.venceEn?.toLocal();
  if (v == null) return false;
  final hoy = ahora.toLocal();
  return v.year == hoy.year && v.month == hoy.month && v.day == hoy.day;
}

/// Mapa a sangre con un lote y un pin de precio por solicitud abierta.
///
/// Verde = abierto, ámbar = vence hoy (DESIGN.md §3). Un pin no se comunica
/// solo con color: lleva el precio escrito en mono y, si vence hoy, la
/// palabra «hoy». Sobre las teselas va el velo `map-dim` para que se lean.
/// El pin seleccionado se llena con el acento.
class MapaSolicitudes extends StatelessWidget {
  const MapaSolicitudes({
    required this.solicitudes,
    required this.alSeleccionar,
    this.seleccionada,
    this.conTeselas,
    this.ahora,
    this.relleno = const EdgeInsets.all(EspaciadoCampo.xxxl),
    super.key,
  });

  final List<SolicitudAbierta> solicitudes;
  final int? seleccionada;
  final ValueChanged<SolicitudAbierta> alSeleccionar;
  final bool? conTeselas;

  /// Reloj para decidir qué vence hoy; por defecto, la hora del dispositivo.
  final DateTime? ahora;

  /// Margen que se reserva al encuadrar (la búsqueda y la hoja inferior
  /// tapan parte del mapa).
  final EdgeInsets relleno;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final teselas = conTeselas ?? ConfiguracionMapa.teselas;
    final hoy = ahora ?? DateTime.now();
    final ubicadas = [
      for (final s in solicitudes)
        if (s.ubicacion != null) s,
    ];
    final puntos = [
      for (final s in ubicadas)
        LatLng(s.ubicacion!.latitud, s.ubicacion!.longitud),
    ];
    return Semantics(
      label: l10n.proveedorNegociacionMapaSemantica(ubicadas.length),
      child: ClipRect(
        child: FlutterMap(
          options: MapOptions(
            backgroundColor: ConfiguracionMapa.fondo(paleta),
            initialCenter: _centroSantaCruz,
            initialZoom: 6.2,
            initialCameraFit: puntos.length >= 2
                ? CameraFit.coordinates(
                    coordinates: puntos,
                    padding: relleno,
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
            // Velo `map-dim`: va sobre las teselas y bajo lotes y pines.
            IgnorePointer(
              child: ColoredBox(
                color: ConfiguracionMapa.velo(paleta),
                child: const SizedBox.expand(),
              ),
            ),
            PolygonLayer(
              polygons: [
                for (final s in ubicadas)
                  _lote(s, paleta, venceHoy(s, hoy), s.id == seleccionada),
              ],
            ),
            _CapaMarcadores(
              solicitudes: ubicadas,
              seleccionada: seleccionada,
              ahora: hoy,
              alSeleccionar: alSeleccionar,
            ),
            if (teselas)
              MediaQuery.withNoTextScaling(
                child: const SimpleAttributionWidget(
                  source: Text('OpenStreetMap'),
                  backgroundColor: ColoresCampo.atribucionMapa,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// El contorno del lote: el polígono real si ya se conoce y, si no, la
  /// huella cuadrada de la misma superficie centrada en el punto. La huella
  /// solo se dibuja; ninguna cuenta de hectáreas sale de ella.
  Polygon _lote(SolicitudAbierta s, PaletaCampo paleta, bool hoy, bool activa) {
    final color = hoy ? paleta.ambar : paleta.acento;
    final puntos = s.terreno != null && s.terreno!.poligono.length >= 3
        ? [for (final p in s.terreno!.poligono) LatLng(p.latitud, p.longitud)]
        : _huella(s.ubicacion!, s.hectareas.toDouble());
    return Polygon(
      points: puntos,
      color: color.withValues(alpha: activa ? 0.38 : 0.22),
      borderColor: color,
      borderStrokeWidth: activa ? 4 : 2.5,
    );
  }

  static List<LatLng> _huella(GeoPunto c, double hectareas) {
    final mitad = math.sqrt(hectareas * 10000) / 2;
    final dLat = mitad / 111320;
    final dLon = mitad / (111320 * math.cos(c.latitud * math.pi / 180));
    return [
      LatLng(c.latitud - dLat, c.longitud - dLon),
      LatLng(c.latitud - dLat, c.longitud + dLon),
      LatLng(c.latitud + dLat, c.longitud + dLon),
      LatLng(c.latitud + dLat, c.longitud - dLon),
    ];
  }
}

/// Capa de pines sin solapes. Con el zoom actual, cada pastilla que tapa a
/// otra ya colocada baja un paso hasta quedar libre; el orden es el de la
/// lista, así que el resultado es determinista. Se reconstruye con la
/// cámara: al acercar, los pines vuelven a su sitio.
class _CapaMarcadores extends StatelessWidget {
  const _CapaMarcadores({
    required this.solicitudes,
    required this.seleccionada,
    required this.ahora,
    required this.alSeleccionar,
  });

  final List<SolicitudAbierta> solicitudes;
  final int? seleccionada;
  final DateTime ahora;
  final ValueChanged<SolicitudAbierta> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final camara = MapCamera.of(context);
    final colocados = <Rect>[];
    final marcadores = <Marker>[];
    for (final s in solicitudes) {
      final punto = LatLng(s.ubicacion!.latitud, s.ubicacion!.longitud);
      final base = camara.latLngToScreenOffset(punto);
      var desplazado = base;
      Rect caja() => Rect.fromCenter(
        center: desplazado,
        width: _anchoPastilla,
        height: _altoPastilla,
      );
      var intentos = 0;
      while (colocados.any((c) => c.overlaps(caja())) &&
          intentos < _maxIntentos) {
        intentos++;
        desplazado = base + Offset(0, intentos * _altoPastilla);
      }
      colocados.add(caja());
      marcadores.add(
        Marker(
          point: intentos == 0
              ? punto
              : camara.screenOffsetToLatLng(desplazado),
          width: _anchoMarcador,
          height: _altoMarcador,
          child: _Marcador(
            solicitud: s,
            activo: s.id == seleccionada,
            hoy: venceHoy(s, ahora),
            alToque: () => alSeleccionar(s),
          ),
        ),
      );
    }
    return MarkerLayer(markers: marcadores);
  }
}

/// Medidas de la pastilla dibujada (con holgura) y del objetivo táctil.
const double _anchoPastilla = 104;
const double _altoPastilla = 38;
const double _anchoMarcador = 132;
const double _altoMarcador = ObjetivoTactilCampo.minimo;
const int _maxIntentos = 12;

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.solicitud,
    required this.activo,
    required this.hoy,
    required this.alToque,
  });

  final SolicitudAbierta solicitud;
  final bool activo;
  final bool hoy;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final propia = solicitud.miNegociacion == MiNegociacion.vigente;
    final fondo = activo ? paleta.acento : paleta.superficie;
    final tinta = activo ? paleta.sobreAcento : paleta.texto;
    final estilo = TipografiaCampo.cifraUnidad.copyWith(
      fontSize: 14,
      color: tinta,
    );
    // Los pines son la vista visual de la lista de la hoja inferior; quien
    // usa un lector de pantalla recorre las tarjetas, que dicen lo mismo y
    // abren el mismo detalle. Por eso no se anuncian dos veces.
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: alToque,
        behavior: HitTestBehavior.opaque,
        child: MediaQuery.withNoTextScaling(
          child: SizedBox.expand(
            child: Center(
              // Con una fuente más ancha la pastilla se encoge, no desborda.
              child: FittedBox(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fondo,
                    borderRadius: BorderRadius.circular(RadioCampo.capsula),
                    border: Border.all(
                      color: hoy ? paleta.ambar : paleta.bordeFuerte,
                      width: hoy || activo ? 2 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: ColoresCampo.sombraPastilla,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspaciadoCampo.m,
                      vertical: EspaciadoCampo.xs + 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (propia) ...[
                          Icon(Icons.handshake_rounded, size: 14, color: tinta),
                          const SizedBox(width: EspaciadoCampo.xs),
                        ],
                        Text(
                          '${FormatoMarketplace.bs(solicitud.precioHaPropuesto)}'
                          '${hoy ? ' · hoy' : ''}',
                          style: estilo,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Las cifras de una solicitud (superficie y precio ofrecido) en dos
/// mosaicos de la misma altura: lo que decide si se ofertará.
class MosaicosSolicitud extends StatelessWidget {
  const MosaicosSolicitud({required this.solicitud, super.key});

  final SolicitudAbierta solicitud;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = solicitud;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Mosaico(
              etiqueta: l10n.proveedorNegociacionSuperficie,
              valor: CifrasNegociacion.ha(s.hectareas),
              unidad: 'ha',
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: _Mosaico(
              etiqueta: l10n.proveedorNegociacionPrecioOfrecido,
              valor: CifrasNegociacion.bsHa(s.precioHaPropuesto),
              unidad: 'Bs/ha',
            ),
          ),
        ],
      ),
    );
  }
}

class _Mosaico extends StatelessWidget {
  const _Mosaico({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
  });

  final String etiqueta;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      container: true,
      label: '$etiqueta: $valor $unidad',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paleta.superficie2,
          borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
        ),
        child: Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TipografiaCampo.cuerpoSecundario.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.xs),
              CifraCampo(valor: valor, unidad: unidad),
            ],
          ),
        ),
      ),
    );
  }
}
