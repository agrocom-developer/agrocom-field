import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sesion_cubit.dart';
import 'sesion_vuelo_vista.dart';

/// Punto de entrada de la pantalla de sesión de vuelo — arma el `SesionCubit`
/// (a través de `crearCubit`, una factory) y se lo provee a [SesionVueloVista].
/// Exclusive del flavor `piloto` — la navegación desde `OrdenDetallePantalla`
/// pasa la factory y el `trabajoUuidCliente` necesarios para construir el Cubit.
class SesionVueloPantalla extends StatelessWidget {
  const SesionVueloPantalla({
    required this.crearCubit,
    required this.trabajoUuidCliente,
    super.key,
  });

  final SesionCubit Function() crearCubit;
  final String trabajoUuidCliente;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SesionCubit>(
      create: (_) => crearCubit(),
      child: SesionVueloVista(trabajoUuidCliente: trabajoUuidCliente),
    );
  }
}
