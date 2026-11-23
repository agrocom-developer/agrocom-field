import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';

/// Pantalla de teléfono (390 x 844 lógicos) y mapas sin red.
void prepararTelefono(WidgetTester tester) {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    ConfiguracionMapa.teselas = true;
  });
}

void prepararIpad(WidgetTester tester) {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = const Size(2388, 1668);
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    ConfiguracionMapa.teselas = true;
  });
}
