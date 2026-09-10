import 'package:flutter/material.dart';

import 'app.dart';
import 'nucleo/di/service_locator.dart';
import 'nucleo/flavor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(flavor: Flavor.piloto);
  runApp(const AgrocomApp(flavor: Flavor.piloto));
}
