import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Hoja inferior que vive sobre el mapa y se arrastra entre un tamaño
/// mínimo (la manija y el encabezado) y uno máximo (la lista completa).
///
/// Mismo aspecto que [HojaInferiorCampo] (radio 32, manija de 36×4), pero no
/// es modal: el mapa sigue a la vista y a la mano. El contenido es una lista
/// que se desplaza cuando la hoja llega arriba, así con texto al 200 % nada
/// se corta. Con movimiento reducido, los saltos de tamaño son instantáneos.
class HojaArrastrableCampo extends StatelessWidget {
  const HojaArrastrableCampo({
    required this.children,
    this.controlador,
    this.tamanoInicial = 0.4,
    this.tamanoMinimo = 0.2,
    this.tamanoMaximo = 0.92,
    super.key,
  });

  /// Lo que va bajo la manija.
  final List<Widget> children;

  /// Para abrir o cerrar la hoja desde fuera (p. ej. al elegir un pin).
  final DraggableScrollableController? controlador;

  /// Fracciones del alto disponible.
  final double tamanoInicial;
  final double tamanoMinimo;
  final double tamanoMaximo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return DraggableScrollableSheet(
      controller: controlador,
      initialChildSize: tamanoInicial,
      minChildSize: tamanoMinimo,
      maxChildSize: tamanoMaximo,
      snap: true,
      // Flutter exige una duración mayor que cero: con movimiento reducido,
      // un milisegundo equivale a un salto.
      snapAnimationDuration: MovimientoCampo.reducido(context)
          ? const Duration(milliseconds: 1)
          : MovimientoCampo.media,
      builder: (context, scroll) => DecoratedBox(
        decoration: BoxDecoration(
          color: ElevacionCampo.superficie(paleta, 2),
          border: Border.all(color: paleta.borde),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadioCampo.hoja),
          ),
          boxShadow: ElevacionCampo.sombras(paleta, 3),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
            EspaciadoCampo.l,
            EspaciadoCampo.m,
            EspaciadoCampo.l,
            EspaciadoCampo.xl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: Semantics(
                label: l10n.componentesArrastraParaVerMas,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: paleta.bordeFuerte,
                    borderRadius: BorderRadius.circular(RadioCampo.capsula),
                  ),
                ),
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            ...children,
          ],
        ),
      ),
    );
  }
}
