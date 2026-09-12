import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../incidencias/presentation/incidencia_cubit.dart';
import 'sesion_bloc.dart';
import 'sesion_vuelo_vista.dart';
import 'trabajo_cubit.dart';

/// Punto de entrada de la pantalla de sesión de vuelo — arma el `SesionBloc`
/// (a través de `crearBloc`, una factory) y se lo provee a [SesionVueloVista],
/// junto con un `TrabajoCubit` NUEVO (a través de `crearTrabajoCubit`, la
/// MISMA factory que ya usa `OrdenDetallePantalla` para abrir el trabajo) —
/// nunca la MISMA instancia que abrió el trabajo: un `BlocProvider` armado en
/// una ruta anterior no es visible vía `context.read` en una ruta nueva
/// empujada con `Navigator.push` (rutas pusheadas son ramas hermanas del
/// `Overlay`, no descendientes — verificado con un widget test antes de
/// escribir esto), así que HU-09 (cerrar trabajo) necesita su propio
/// `BlocProvider<TrabajoCubit>` acá, en la ruta donde se lo va a leer.
/// Exclusive del flavor `piloto` — la navegación desde `OrdenDetallePantalla`
/// pasa las factories necesarias para construir el Bloc/Cubit (que ya
/// captura el `trabajoUuidCliente` del trabajo recién abierto) y el
/// `IncidenciaCubit` de HU-08 (que la vista arma recién al reportar una
/// incidencia, con el `sesionUuidCliente` de la sesión activa en ese
/// momento).
class SesionVueloPantalla extends StatelessWidget {
  const SesionVueloPantalla({
    required this.crearBloc,
    required this.crearTrabajoCubit,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final SesionBloc Function() crearBloc;
  final TrabajoCubit Function() crearTrabajoCubit;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SesionBloc>(create: (_) => crearBloc()),
        BlocProvider<TrabajoCubit>(create: (_) => crearTrabajoCubit()),
      ],
      child: SesionVueloVista(crearIncidenciaCubit: crearIncidenciaCubit),
    );
  }
}
