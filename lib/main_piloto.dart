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
  await configurarDependencias(flavor: Flavor.piloto);
  runApp(
    AgrocomApp(
      flavor: Flavor.piloto,
      tokenStore: getIt<TokenStore>(),
      crearLoginCubit: () => LoginCubit(getIt<LoginService>()),
      crearOrdenesCubit: () => OrdenesCubit(getIt<OrdenesRepository>()),
    ),
  );
}
