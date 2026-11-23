// Genera las capturas de docs/diseno/capturas/ con el motor de Flutter
// (render de la vitrina "Sistema" a tamaño de iPhone 17 Pro y de iPad Pro 11)
// y las compara en cada corrida: si el sistema visual cambia, la captura
// cambia y el diff queda en el PR. Se regeneran con
// `flutter test --update-goldens test/nucleo/ui/vitrina_campo/capturas_sistema_visual_test.dart`.
//
// Solo corren en macOS (el render de texto difiere en Linux).

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/vitrina_campo/sistema_visual_campo_vitrina.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
  await cargador.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _cargarFuente('Manrope', 'assets/fonts/Manrope.ttf');
    await _cargarFuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await _cargarFuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  final saltar = !Platform.isMacOS;

  Future<void> capturar(
    WidgetTester tester, {
    required Size tamano,
    required String archivo,
    String? modo,
  }) async {
    tester.view.physicalSize = tamano * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.campo),
        home: const Scaffold(
          body: SafeArea(child: SistemaVisualCampoVitrina()),
        ),
      ),
    );
    if (modo != null) {
      await tester.tap(find.text(modo));
      // Deja terminar la transición de tema (el esqueleto repite sin fin,
      // así que no sirve pumpAndSettle).
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../../docs/diseno/capturas/$archivo'),
    );
  }

  testWidgets('iPhone 17 Pro, modo claro', skip: saltar, (tester) async {
    await capturar(
      tester,
      tamano: const Size(402, 1500),
      archivo: 'iphone17pro_claro.png',
    );
  });

  testWidgets('iPhone 17 Pro, modo oscuro', skip: saltar, (tester) async {
    await capturar(
      tester,
      tamano: const Size(402, 1500),
      archivo: 'iphone17pro_oscuro.png',
      modo: 'Oscuro',
    );
  });

  testWidgets('iPhone 17 Pro, modo campo', skip: saltar, (tester) async {
    await capturar(
      tester,
      tamano: const Size(402, 1500),
      archivo: 'iphone17pro_campo.png',
      modo: 'Campo',
    );
  });

  testWidgets('iPad Pro 11, modo claro', skip: saltar, (tester) async {
    await capturar(
      tester,
      tamano: const Size(834, 1194),
      archivo: 'ipadpro11_claro.png',
    );
  });
}
