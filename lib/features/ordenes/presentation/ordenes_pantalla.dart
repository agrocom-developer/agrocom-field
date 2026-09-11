import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ordenes_cubit.dart';
import 'ordenes_vista.dart';

/// Punto de entrada de la pantalla de órdenes — arma el `OrdenesCubit` (a
/// través de `crearCubit`, normalmente `() => getIt<OrdenesCubit>()`) y se
/// lo provee a [OrdenesVista]. Compartida por los dos flavors: ambos roles
/// pueden ver órdenes (espec §3), así que vive en `features/ordenes`, no en
/// `piloto/` ni `auxiliar/` (invariante 7 de CLAUDE.md).
class OrdenesPantalla extends StatelessWidget {
  const OrdenesPantalla({required this.crearCubit, super.key});

  final OrdenesCubit Function() crearCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdenesCubit>(
      create: (_) => crearCubit(),
      child: const OrdenesVista(),
    );
  }
}
