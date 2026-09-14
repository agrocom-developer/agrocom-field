import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'incidencia_cubit.dart';
import 'incidencia_vista.dart';

/// Punto de entrada de la pantalla de incidencia — arma el
/// `IncidenciaCubit` (a través de `crearCubit`, una factory) y se lo provee
/// a [IncidenciaVista]. Exclusiva del flavor `piloto` — se navega acá desde
/// `SesionVueloVista` cuando hay una sesión activa (invariante 4 de
/// CLAUDE.md: el flavor `auxiliar` no tiene `SesionLocal`, así que no tiene
/// `sesionUuidCliente` contra qué referenciar).
class IncidenciaPantalla extends StatelessWidget {
  const IncidenciaPantalla({required this.crearCubit, super.key});

  final IncidenciaCubit Function() crearCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IncidenciaCubit>(
      create: (_) => crearCubit(),
      child: const IncidenciaVista(),
    );
  }
}
