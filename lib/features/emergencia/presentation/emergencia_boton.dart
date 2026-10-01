import 'package:flutter/material.dart';

import '../../../nucleo/flavor.dart';
import '../../../nucleo/linterna/linterna_controlador.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import 'linterna_panel.dart';

/// Punto de entrada de un toque al modo emergencia (HU-68, Sprint 15 —
/// exclusivo del flavor auxiliar, el RC no recibe trabajo nuevo este
/// sprint). Envuelve el árbol de la app en un `Stack` para quedar visible
/// desde cualquier pantalla — incluida la de login, sin sesión iniciada ni
/// señal — en vez de montarse dentro de una ruta particular.
///
/// En modo campo (ADR 0008, decisión del 1/10/2026): botón en
/// `acentoRojo` —el color semántico de error/alerta del catálogo— y panel
/// sobre `superficie`, con el radio de tarjeta grande arriba.
class EmergenciaBoton extends StatelessWidget {
  const EmergenciaBoton({
    required this.flavor,
    required this.linternaControlador,
    required this.child,
    super.key,
  });

  final Flavor flavor;
  final LinternaControlador linternaControlador;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (flavor != Flavor.auxiliar) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: FloatingActionButton(
              key: const Key('emergencia_boton'),
              heroTag: 'emergencia_boton',
              backgroundColor: ColoresCampo.acentoRojo,
              foregroundColor: ColoresCampo.fondoProfundo,
              onPressed: () => _abrirPanel(context),
              child: const Icon(Icons.warning_amber_rounded),
            ),
          ),
        ),
      ],
    );
  }

  void _abrirPanel(BuildContext context) {
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaGrande ??
        const TemaCampo().radioTarjetaGrande;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColoresCampo.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radio)),
      ),
      builder: (_) => LinternaPanel(controlador: linternaControlador),
    );
  }
}
