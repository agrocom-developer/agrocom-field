import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'cliente/app_cliente.dart';
import 'cliente/di/dependencias_cliente.dart';
import 'nucleo/api/api_client.dart';
import 'nucleo/auth/dispositivo_store.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/di/service_locator_cliente.dart';
import 'nucleo/entorno/api_base_url.dart';
import 'nucleo/entorno/info_entorno.dart';
import 'nucleo/entorno/modo_demo.dart';
import 'nucleo/flavor.dart';

/// Entrypoint del flavor `cliente` (online-first, sin `drift` ni outbox).
///
/// Con `MODO_DEMO` corre contra repositorios en memoria con datos ficticios,
/// sin red (`--dart-define-from-file=config/env.demo.json`, ADR 0010). Sin
/// él, corre contra la API de `API_BASE_URL` (`config/env.local.json`,
/// `env.staging.json`, `env.produccion.json`; ADR 0004).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (modoDemo) {
    // La demo arranca como recién instalada: presentación, acceso e inicio.
    runApp(AppCliente(dependencias: DependenciasCliente.demo(primerUso: true)));
    return;
  }

  await configurarDependenciasCliente();
  final getIt = GetIt.instance;
  final paquete = await PackageInfo.fromPlatform();
  final infoEntorno = InfoEntorno(
    flavor: Flavor.cliente,
    hostApi: InfoEntorno.hostDe(apiBaseUrl),
    version: '${paquete.version}+${paquete.buildNumber}',
  );
  runApp(
    AppCliente(
      dependencias: DependenciasCliente.red(
        api: getIt<ApiClient>(),
        tokenStore: getIt<TokenStore>(),
        dispositivoStore: DispositivoStoreSeguro(),
        // El host y la versión al pie del ingreso: un build apuntado al
        // entorno equivocado se nota antes de operar (ADR 0004).
        notaAcceso: 'Servidor ${infoEntorno.hostApi} · v${infoEntorno.version}',
      ),
    ),
  );
}
