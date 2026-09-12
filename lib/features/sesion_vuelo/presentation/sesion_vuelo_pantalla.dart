import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../incidencias/presentation/incidencia_cubit.dart';
import 'sesion_bloc.dart';
import 'sesion_vuelo_vista.dart';

/// Punto de entrada de la pantalla de sesión de vuelo — arma el `SesionBloc`
/// (a través de `crearBloc`, una factory) y se lo provee a [SesionVueloVista].
/// Exclusive del flavor `piloto` — la navegación desde `OrdenDetallePantalla`
/// pasa las factories necesarias para construir el Bloc (que ya captura el
/// `trabajoUuidCliente` del trabajo recién abierto) y el `IncidenciaCubit`
/// de HU-08 (que la vista arma recién al reportar una incidencia, con el
/// `sesionUuidCliente` de la sesión activa en ese momento).
class SesionVueloPantalla extends StatelessWidget {
  const SesionVueloPantalla({
    required this.crearBloc,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final SesionBloc Function() crearBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SesionBloc>(
      create: (_) => crearBloc(),
      child: SesionVueloVista(crearIncidenciaCubit: crearIncidenciaCubit),
    );
  }
}
