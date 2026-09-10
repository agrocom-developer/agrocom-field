import 'package:flutter/material.dart';

import 'app.dart';
import 'nucleo/flavor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgrocomApp(flavor: Flavor.piloto));
}
