import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sesion_bloc.dart';
import 'sesion_vuelo_vista.dart';

/// Punto de entrada de la pantalla de sesión de vuelo — arma el `SesionBloc`
/// (a través de `crearBloc`, una factory) y se lo provee a [SesionVueloVista].
/// Exclusive del flavor `piloto` — la navegación desde `OrdenDetallePantalla`
/// pasa la factory necesaria para construir el Bloc (que ya captura el
/// `trabajoUuidCliente` del trabajo recién abierto).
class SesionVueloPantalla extends StatelessWidget {
  const SesionVueloPantalla({required this.crearBloc, super.key});

  final SesionBloc Function() crearBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SesionBloc>(
      create: (_) => crearBloc(),
      child: const SesionVueloVista(),
    );
  }
}
