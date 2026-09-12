import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/flavor.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import 'ordenes_cubit.dart';
import 'ordenes_vista.dart';

/// Punto de entrada de la pantalla de órdenes — arma el `OrdenesCubit` (a
/// través de `crearCubit`, normalmente `() => getIt<OrdenesCubit>()`) y se
/// lo provee a [OrdenesVista]. Compartida por los dos flavors: ambos roles
/// pueden ver órdenes (espec §3), así que vive en `features/ordenes`, no en
/// `piloto/` ni `auxiliar/` (invariante 7 de CLAUDE.md).
///
/// Propaga las factories de [TrabajoCubit] y [SesionBloc] para HU-05 (etapa 4)
/// y de [IncidenciaCubit] para HU-08 — solo serán usadas si el flavor es
/// `piloto`.
class OrdenesPantalla extends StatelessWidget {
  const OrdenesPantalla({
    required this.crearCubit,
    required this.flavor,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final OrdenesCubit Function() crearCubit;
  final Flavor flavor;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdenesCubit>(
      create: (_) => crearCubit(),
      child: OrdenesVista(
        flavor: flavor,
        crearTrabajoCubit: crearTrabajoCubit,
        crearSesionBloc: crearSesionBloc,
        crearIncidenciaCubit: crearIncidenciaCubit,
      ),
    );
  }
}
