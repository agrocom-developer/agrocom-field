import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import 'inicio_cubit.dart';
import 'inicio_vista.dart';

/// Punto de entrada de «Inicio» del flavor piloto (HU-70) — arma el
/// `InicioCubit` (trabajo asignado, leído de `drift`) y el `TrabajoCubit`
/// que «Crear aplicación» usa para abrir sesión sobre ese trabajo, y se los
/// provee a [InicioVista]. Exclusiva del flavor piloto: solo
/// `main_piloto.dart` la monta.
///
/// [construirOrdenes] arma la pantalla de órdenes vigentes para el destino
/// «Órdenes» de la barra — se recibe ya armada desde la raíz de la app en
/// vez de importar `features/ordenes`, para no acoplar las dos features.
class InicioPantalla extends StatelessWidget {
  const InicioPantalla({
    required this.crearCubit,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    required this.construirOrdenes,
    super.key,
  });

  final InicioCubit Function() crearCubit;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;
  final WidgetBuilder construirOrdenes;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InicioCubit>(create: (_) => crearCubit()),
        BlocProvider<TrabajoCubit>(create: (_) => crearTrabajoCubit()),
      ],
      child: InicioVista(
        crearTrabajoCubit: crearTrabajoCubit,
        crearSesionBloc: crearSesionBloc,
        crearIncidenciaCubit: crearIncidenciaCubit,
        construirOrdenes: construirOrdenes,
      ),
    );
  }
}
