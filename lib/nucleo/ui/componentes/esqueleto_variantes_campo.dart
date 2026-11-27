import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'esqueleto_campo.dart';
import 'tarjeta_campo.dart';

/// Formas de [EsqueletoCampo] recortadas a la silueta de un componente real
/// — así la lista no "salta" cuando llegan los datos: el esqueleto ya ocupa
/// el espacio y la posición exacta del contenido final. Las cuatro variantes
/// que pide el catálogo: oferta, fila de lista, perfil y mapa.
///
/// Comparten el envoltorio `Semantics` con el texto "Cargando" (una sola
/// vez, no por bloque) y respetan "reducir movimiento" porque delegan el
/// barrido en [EsqueletoCampo].
class EsqueletoTarjetaOfertaCampo extends StatelessWidget {
  const EsqueletoTarjetaOfertaCampo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Semantics(
      label: l10n.componentesCargando,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        decoration: BoxDecoration(
          color: ElevacionCampo.superficie(paleta, 2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: paleta.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: const EsqueletoCampo(alto: 12)),
                const SizedBox(width: EspaciadoCampo.m),
                const EsqueletoCampo(ancho: 56, alto: 56, radio: 28),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.l),
            const EsqueletoCampo(ancho: 160, alto: 22),
            const SizedBox(height: EspaciadoCampo.s),
            const EsqueletoCampo(alto: 14),
            const SizedBox(height: EspaciadoCampo.l),
            const EsqueletoCampo(alto: 132, radio: 16),
            const SizedBox(height: EspaciadoCampo.l),
            Row(
              children: [
                Expanded(child: const EsqueletoCampo(alto: 32)),
                const SizedBox(width: EspaciadoCampo.l),
                Expanded(child: const EsqueletoCampo(alto: 32)),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            const EsqueletoCampo(alto: ObjetivoTactilCampo.guantes, radio: 28),
          ],
        ),
      ),
    );
  }
}

/// Fila de lista en espera — misma geometría que `ItemListaCampo`.
class EsqueletoFilaListaCampo extends StatelessWidget {
  const EsqueletoFilaListaCampo({super.key});

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const EsqueletoCampo(ancho: 38, alto: 38, radio: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const EsqueletoCampo(ancho: 140, alto: 15),
                const SizedBox(height: 6),
                const EsqueletoCampo(ancho: 90, alto: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const EsqueletoCampo(ancho: 48, alto: 16),
        ],
      ),
    );
  }
}

/// Encabezado de perfil en espera: avatar circular, nombre y una fila de
/// métricas. Para el perfil del proveedor y el detalle de un piloto elegido.
class EsqueletoPerfilCampo extends StatelessWidget {
  const EsqueletoPerfilCampo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const EsqueletoCampo(ancho: 72, alto: 72, radio: 36),
            const SizedBox(width: EspaciadoCampo.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EsqueletoCampo(ancho: 150, alto: 20),
                  const SizedBox(height: EspaciadoCampo.s),
                  const EsqueletoCampo(ancho: 100, alto: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: EspaciadoCampo.l),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EsqueletoCampo(alto: 22),
                    const SizedBox(height: EspaciadoCampo.xs),
                    const EsqueletoCampo(alto: 10),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Rectángulo a sangre con un marcador fijo — lo que ocupa `MapaLote` o
/// `MapaExpandibleCampo` mientras no hay posición ni lotes para dibujar.
class EsqueletoMapaCampo extends StatelessWidget {
  const EsqueletoMapaCampo({this.alto = 180, super.key});

  final double alto;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadioCampo.media),
      child: SizedBox(
        height: alto,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: EsqueletoCampo(radio: 0, alto: alto)),
            Icon(
              Icons.location_on_rounded,
              size: 28,
              color: paleta.texto.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }
}
