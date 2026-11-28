import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../../ui/transiciones_campo.dart';
import '../dominio/dominio.dart';
import 'mapa_lote.dart';

/// Mapa con expansión a pantalla completa, reutilizable por `cliente` y
/// `piloto`: la miniatura vive dentro de una tarjeta (oferta, seguimiento
/// del servicio) y un toque la lleva a una página propia con el mismo mapa
/// más grande, controles de zoom y recentrado accesibles (48 px) y un botón
/// de cerrar. La transición es [TransicionesCampo.modal] (entra desde abajo
/// con un fundido): explica que la pantalla nueva es la continuación de la
/// miniatura, sin decorar.
///
/// No usa `Hero` sobre el mapa interactivo: `FlutterMap` adjunta su propio
/// `MapController` al montarse, y el vuelo de un `Hero` puede montar el
/// mismo subárbol dos veces a la vez (una para medirlo, otra para la
/// posición final) — con un `MapController` de por medio eso termina en un
/// `setState` durante el build de la otra instancia. Una miniatura no
/// interactiva más una transición con intención evita el riesgo sin perder
/// la sensación de "la miniatura se agranda".
///
/// No guarda ninguna posición: solo pinta lo que ya recibió en [posicionDron]
/// y [lotes] (invariante de privacidad de ubicación de `CLAUDE.md`).
class MapaExpandibleCampo extends StatelessWidget {
  const MapaExpandibleCampo({
    required this.lotes,
    this.seleccionado,
    this.posicionDron,
    this.trazado = const [],
    this.altoMiniatura = 180,
    this.radio = RadioCampo.media,
    super.key,
  });

  final List<Lote> lotes;
  final Lote? seleccionado;
  final GeoPunto? posicionDron;
  final List<GeoPunto> trazado;
  final double altoMiniatura;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Stack(
        children: [
          SizedBox(
            height: altoMiniatura,
            width: double.infinity,
            child: IgnorePointer(
              child: MapaLote(
                lotes: lotes,
                seleccionado: seleccionado,
                posicionDron: posicionDron,
                trazado: trazado,
                interactivo: false,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  TransicionesCampo.modal<void>(
                    (context) => _MapaPantallaCompletaCampo(
                      lotes: lotes,
                      seleccionado: seleccionado,
                      posicionDron: posicionDron,
                      trazado: trazado,
                    ),
                  ),
                ),
                child: Semantics(button: true, label: l10n.mapaExpandibleAbrir),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapaPantallaCompletaCampo extends StatefulWidget {
  const _MapaPantallaCompletaCampo({
    required this.lotes,
    required this.seleccionado,
    required this.posicionDron,
    required this.trazado,
  });

  final List<Lote> lotes;
  final Lote? seleccionado;
  final GeoPunto? posicionDron;
  final List<GeoPunto> trazado;

  @override
  State<_MapaPantallaCompletaCampo> createState() =>
      _MapaPantallaCompletaCampoState();
}

class _MapaPantallaCompletaCampoState
    extends State<_MapaPantallaCompletaCampo> {
  final _controlador = MapController();

  void _acercar() {
    final camara = _controlador.camera;
    _controlador.move(camara.center, camara.zoom + 1);
  }

  void _alejar() {
    final camara = _controlador.camera;
    _controlador.move(camara.center, camara.zoom - 1);
  }

  void _recentrar() {
    final puntos = [
      for (final l in widget.lotes) ...l.poligono,
      ?widget.posicionDron,
    ];
    if (puntos.isEmpty) return;
    _controlador.fitCamera(
      CameraFit.coordinates(
        coordinates: [for (final p in puntos) LatLng(p.latitud, p.longitud)],
        padding: const EdgeInsets.all(40),
        maxZoom: 16.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Scaffold(
      backgroundColor: paleta.fondo,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapaLote(
              lotes: widget.lotes,
              seleccionado: widget.seleccionado,
              posicionDron: widget.posicionDron,
              trazado: widget.trazado,
              controlador: _controlador,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ControlMapaCampo(
                    icono: Icons.close_rounded,
                    tooltip: l10n.mapaExpandibleCerrar,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Column(
                    children: [
                      _ControlMapaCampo(
                        icono: Icons.add_rounded,
                        tooltip: l10n.mapaExpandibleAcercar,
                        onPressed: _acercar,
                      ),
                      const SizedBox(height: EspaciadoCampo.s),
                      _ControlMapaCampo(
                        icono: Icons.remove_rounded,
                        tooltip: l10n.mapaExpandibleAlejar,
                        onPressed: _alejar,
                      ),
                      const SizedBox(height: EspaciadoCampo.s),
                      _ControlMapaCampo(
                        icono: Icons.my_location_rounded,
                        tooltip: l10n.mapaExpandibleRecentrar,
                        onPressed: _recentrar,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlMapaCampo extends StatelessWidget {
  const _ControlMapaCampo({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Container(
      width: ObjetivoTactilCampo.minimo,
      height: ObjetivoTactilCampo.minimo,
      decoration: BoxDecoration(
        color: paleta.superficieElevada,
        shape: BoxShape.circle,
        border: Border.all(color: paleta.borde),
      ),
      child: IconButton(
        icon: Icon(icono, color: paleta.texto),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
