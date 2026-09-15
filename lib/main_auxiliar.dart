import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'features/auth/login_cubit.dart';
import 'features/avisos_locales/data/avisos_locales_watcher.dart';
import 'features/avisos_locales/data/ids_vistos_store.dart';
import 'features/ordenes/data/ordenes_repository.dart';
import 'features/ordenes/presentation/ordenes_cubit.dart';
import 'nucleo/auth/login_service.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/di/service_locator.dart';
import 'nucleo/entorno/info_entorno.dart';
import 'nucleo/flavor.dart';
import 'nucleo/linterna/linterna_controlador.dart';
import 'nucleo/notificaciones/notificador_local.dart';
import 'nucleo/sync/disparador_sync.dart';
import 'nucleo/version/version_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(flavor: Flavor.auxiliar);

  // Lo que el pie del login muestra para reconocer el entorno (ADR 0004) y
  // la versión instalada (ADR 0007). `PackageInfo` lee del propio APK — no
  // es red, así que sí se espera antes de `runApp`.
  final paquete = await PackageInfo.fromPlatform();
  final infoEntorno = InfoEntorno(
    flavor: Flavor.auxiliar,
    hostApi: InfoEntorno.hostDe(apiBaseUrl),
    version: '${paquete.version}+${paquete.buildNumber}',
  );

  // HU-62, Sprint 15 (enteramente auxiliar — el flavor piloto no recibe
  // trabajo nuevo todavía): de vida larga, no atado al ciclo de una
  // pantalla particular, por eso se arranca acá y no dentro de AgrocomApp.
  // No se espera el permiso antes de `runApp`: pedirlo bloquearía el primer
  // frame por un diálogo del sistema operativo que no es indispensable
  // para que la app arranque (si queda denegado, `mostrar()` simplemente no
  // hace nada — no hay camino de error que manejar acá).
  unawaited(getIt<NotificadorLocal>().pedirPermiso());
  await AvisosLocalesWatcher(
    ordenesRepositorio: getIt<OrdenesRepository>(),
    notificador: getIt<NotificadorLocal>(),
    idsVistosStore: getIt<IdsVistosStore>(),
  ).iniciar();

  // HU-20: mismo criterio que en main_piloto.dart — no se espera, la app
  // nunca depende de que la red responda para arrancar.
  unawaited(getIt<VersionWatcher>().iniciar());

  // TE-19: mismo criterio — el primer ciclo de sync puede tardar o no
  // tener red, y la app nunca espera la red para arrancar.
  unawaited(getIt<DisparadorSync>().iniciar());

  runApp(
    AgrocomApp(
      flavor: Flavor.auxiliar,
      infoEntorno: infoEntorno,
      tokenStore: getIt<TokenStore>(),
      linternaControlador: getIt<LinternaControlador>(),
      estadoVersion: getIt<VersionWatcher>().estado,
      crearLoginCubit: () => LoginCubit(getIt<LoginService>(), Flavor.auxiliar),
      crearOrdenesCubit: () => OrdenesCubit(getIt<OrdenesRepository>()),
      // Stubs: el flavor auxiliar no usa trabajo/sesión/incidencia, pero
      // AgrocomApp requiere las factories para mantener la interfaz
      // consistente. Estas nunca se invocan en el flujo auxiliar:
      // `OrdenDetallePantalla` solo arma el `BlocProvider<TrabajoCubit>` (y
      // por lo tanto solo puede llegar a necesitar `crearSesionBloc`/
      // `crearIncidenciaCubit`) cuando flavor == piloto.
      crearTrabajoCubit: () => throw UnimplementedError(
        'El flavor auxiliar no dispone de trabajo/sesión',
      ),
      crearSesionBloc: (_) => throw UnimplementedError(
        'El flavor auxiliar no dispone de trabajo/sesión',
      ),
      crearIncidenciaCubit: (_) => throw UnimplementedError(
        'El flavor auxiliar no dispone de trabajo/sesión',
      ),
      alIngresarConExito: () =>
          unawaited(getIt<DisparadorSync>().sincronizarAhora()),
    ),
  );
}
