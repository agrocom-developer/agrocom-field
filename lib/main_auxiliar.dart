import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/login_cubit.dart';
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
      crearLoginCubit: () => LoginCubit(getIt<LoginService>()),
    ),
  );
}
