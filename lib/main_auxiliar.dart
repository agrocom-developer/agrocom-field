import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/login_cubit.dart';
import 'features/ordenes/data/ordenes_repository.dart';
import 'features/ordenes/presentation/ordenes_cubit.dart';
import 'nucleo/auth/login_service.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/di/service_locator.dart';
import 'nucleo/flavor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(flavor: Flavor.auxiliar);
  runApp(
    AgrocomApp(
      flavor: Flavor.auxiliar,
      tokenStore: getIt<TokenStore>(),
      crearLoginCubit: () => LoginCubit(getIt<LoginService>(), Flavor.auxiliar),
      crearOrdenesCubit: () => OrdenesCubit(getIt<OrdenesRepository>()),
      // Stubs: el flavor auxiliar no usa trabajo/sesión, pero AgrocomApp
      // requiere las factories para mantener la interfaz consistente. Estas
      // nunca se invocan en el flujo auxiliar: `OrdenDetallePantalla` solo
      // arma el `BlocProvider<TrabajoCubit>` (y por lo tanto solo puede
      // llegar a necesitar `crearSesionBloc`) cuando flavor == piloto.
      crearTrabajoCubit: () => throw UnimplementedError(
        'El flavor auxiliar no dispone de trabajo/sesión',
      ),
      crearSesionBloc: (_) => throw UnimplementedError(
        'El flavor auxiliar no dispone de trabajo/sesión',
      ),
    ),
  );
}
