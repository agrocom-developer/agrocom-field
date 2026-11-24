import 'package:flutter/widgets.dart';

import '../../incidencias/presentation/incidencia_cubit.dart';
import 'sesion_bloc.dart';
import 'sesion_vuelo_pantalla.dart';
import 'trabajo_cubit.dart';

/// Las tres factories que arman la pantalla de sesión de vuelo, juntas en
/// un solo valor para proveerlas por encima del `Navigator`
/// (`RepositoryProvider<FabricasSesionVuelo>`): una pantalla de servicio
/// abre la sesión sin conocer los repositorios que hay detrás.
class FabricasSesionVuelo {
  const FabricasSesionVuelo({
    required this.crearSesionBloc,
    required this.crearTrabajoCubit,
    required this.crearIncidenciaCubit,
  });

  final SesionBloc Function(String trabajoUuidCliente) crearSesionBloc;
  final TrabajoCubit Function() crearTrabajoCubit;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  /// Pantalla de sesión de vuelo del trabajo [trabajoUuidCliente]: arranca
  /// en la sesión que haya quedado abierta.
  Widget pantalla(String trabajoUuidCliente) => SesionVueloPantalla(
    crearBloc: () => crearSesionBloc(trabajoUuidCliente),
    crearTrabajoCubit: crearTrabajoCubit,
    crearIncidenciaCubit: crearIncidenciaCubit,
  );
}
