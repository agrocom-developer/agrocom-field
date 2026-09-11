import 'package:flutter/material.dart';

import '../../../nucleo/flavor.dart';
import '../../../nucleo/linterna/linterna_controlador.dart';
import 'linterna_panel.dart';

/// Punto de entrada de un toque al modo emergencia (HU-68, Sprint 15 —
/// exclusivo del flavor auxiliar, el RC no recibe trabajo nuevo este
/// sprint). Envuelve el árbol de la app en un `Stack` para quedar visible
/// desde cualquier pantalla — incluida la de login, sin sesión iniciada ni
/// señal — en vez de montarse dentro de una ruta particular.
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              onPressed: () => _abrirPanel(context),
              child: const Icon(Icons.warning_amber_rounded),
            ),
          ),
        ),
      ],
    );
  }

  void _abrirPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => LinternaPanel(controlador: linternaControlador),
    );
  }
}
