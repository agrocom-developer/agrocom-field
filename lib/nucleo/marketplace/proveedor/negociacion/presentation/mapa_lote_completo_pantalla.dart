import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/mapa_lote.dart';
import '../../ejecucion/domain/ejecucion.dart';
import 'distancia_al_lote_vista.dart';

/// El mapa del lote a pantalla completa, con la distancia al lote en una
/// franja inferior. Es el punto de integración del componente de mapa
/// expandible del sistema de UI: cuando exista, reemplaza el cuerpo de esta
/// pantalla sin cambiar quién la abre.
class MapaLoteCompletoPantalla extends StatelessWidget {
  const MapaLoteCompletoPantalla({
    required this.lote,
    required this.servicioUbicacion,
    this.centro,
    super.key,
  });

  final Lote lote;

  /// Punto al que se mide la distancia; por defecto, el centro del lote.
  final GeoPunto? centro;
  final ServicioUbicacion servicioUbicacion;

  /// Abre el mapa en pantalla completa con una transición corta.
  static Future<void> abrir(
    BuildContext context, {
    required Lote lote,
    required ServicioUbicacion servicioUbicacion,
    GeoPunto? centro,
  }) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: MovimientoCampo.duracion(
        context,
        MovimientoCampo.media,
      ),
      reverseTransitionDuration: MovimientoCampo.duracion(
        context,
        MovimientoCampo.rapida,
      ),
      pageBuilder: (_, _, _) => MapaLoteCompletoPantalla(
        lote: lote,
        centro: centro,
        servicioUbicacion: servicioUbicacion,
      ),
      transitionsBuilder: (_, animacion, _, hijo) => FadeTransition(
        opacity: CurvedAnimation(
          parent: animacion,
          curve: MovimientoCampo.entrada,
        ),
        child: hijo,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapaCompletoTitulo),
        leading: IconButton(
          key: const ValueKey('mapa-cerrar'),
          tooltip: l10n.mapaCerrarCompleto,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MapaLote(lotes: [lote], seleccionado: lote),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: paleta.superficie,
              border: Border(top: BorderSide(color: paleta.borde)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.l),
                child: DistanciaAlLoteVista(
                  lote: centro ?? lote.centro,
                  servicio: servicioUbicacion,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
