import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/login_cubit.dart';
import 'features/incidencias/data/incidencia_repository.dart';
import 'features/incidencias/presentation/incidencia_cubit.dart';
import 'features/ordenes/data/ordenes_repository.dart';
import 'features/ordenes/presentation/ordenes_cubit.dart';
import 'features/sesion_vuelo/data/trabajo_repository.dart';
import 'features/sesion_vuelo/data/sesion_repository.dart';
import 'features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'nucleo/auth/login_service.dart';
import 'nucleo/auth/persona_operativa_store.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/camara/selector_foto.dart';
import 'nucleo/di/service_locator.dart';
import 'nucleo/flavor.dart';
import 'nucleo/linterna/linterna_controlador.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(flavor: Flavor.piloto);
  runApp(
    AgrocomApp(
      flavor: Flavor.piloto,
      tokenStore: getIt<TokenStore>(),
      linternaControlador: getIt<LinternaControlador>(),
      crearLoginCubit: () => LoginCubit(getIt<LoginService>(), Flavor.piloto),
      crearOrdenesCubit: () => OrdenesCubit(getIt<OrdenesRepository>()),
      crearTrabajoCubit: () => TrabajoCubit(getIt<TrabajoRepository>()),
      crearSesionBloc: (trabajoUuidCliente) => SesionBloc(
        sesionRepositorio: getIt<SesionRepository>(),
        personaOperativaStore: getIt<PersonaOperativaStore>(),
        trabajoUuidCliente: trabajoUuidCliente,
      ),
      crearIncidenciaCubit: (sesionUuidCliente) => IncidenciaCubit(
        incidenciaRepositorio: getIt<IncidenciaRepository>(),
        selectorFoto: getIt<SelectorFoto>(),
        sesionUuidCliente: sesionUuidCliente,
      ),
    ),
  );
}
