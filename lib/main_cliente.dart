import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'cliente/app_cliente.dart';
import 'cliente/di/dependencias_cliente.dart';
import 'cliente/inicio_minimo_cliente.dart';
import 'nucleo/di/service_locator_cliente.dart';
import 'nucleo/entorno/api_base_url.dart';
import 'nucleo/entorno/info_entorno.dart';
import 'nucleo/entorno/modo_demo.dart';
import 'nucleo/flavor.dart';
import 'nucleo/ui/paleta_campo.dart';
import 'nucleo/ui/tema_campo.dart';

/// Entrypoint del flavor `cliente` (online-first, sin `drift` ni outbox).
///
/// Con `MODO_DEMO` corre contra repositorios en memoria con datos ficticios,
/// sin red (`--dart-define-from-file=config/env.demo.json`, ADR 0010).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (modoDemo) {
    runApp(AppCliente(dependencias: DependenciasCliente.demo()));
    return;
  }

  await configurarDependenciasCliente();
  final paquete = await PackageInfo.fromPlatform();
  final infoEntorno = InfoEntorno(
    flavor: Flavor.cliente,
    hostApi: InfoEntorno.hostDe(apiBaseUrl),
    version: '${paquete.version}+${paquete.buildNumber}',
  );
  runApp(
    MaterialApp(
      title: 'Agrocom',
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
      darkTheme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.oscuro),
      home: InicioMinimoCliente(infoEntorno: infoEntorno),
    ),
  );
}
