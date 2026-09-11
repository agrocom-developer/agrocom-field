import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_cubit.dart';
import 'login_vista.dart';

/// Punto de entrada de la pantalla de login — arma el `LoginCubit` (a
/// través de `crearCubit`, normalmente `() => getIt<LoginCubit>()`) y se lo
/// provee a [LoginVista]. Compartida por los dos flavors (ver invariante 7
/// de `CLAUDE.md`: `piloto/` y `auxiliar/` no se importan entre sí, así que
/// esta pantalla vive en `features/auth`, no en uno de los dos).
class LoginPantalla extends StatelessWidget {
  const LoginPantalla({
    required this.crearCubit,
    required this.onIngresoExitoso,
    super.key,
  });

  final LoginCubit Function() crearCubit;
  final VoidCallback onIngresoExitoso;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => crearCubit(),
      child: LoginVista(onIngresoExitoso: onIngresoExitoso),
    );
  }
}
