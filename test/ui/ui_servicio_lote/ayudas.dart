// Ayudas de las pruebas de UI del servicio en el lote (tarea 46): cada
// pantalla se monta en 360x640 y 412x915, con el texto al 100 % y al 200 %.
// En toda plataforma se verifica que no haya desbordes; el golden se compara
// solo en macOS, donde se generan las referencias (el render de texto
// difiere en Linux).
//
// Regenerar: `flutter test --update-goldens test/ui/ui_servicio_lote`.

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const tamanos = [Size(360, 640), Size(412, 915)];
const escalas = [1.0, 2.0];

/// Momento fijo para que ninguna referencia dependa del reloj.
final ahoraFijo = DateTime(2026, 11, 23, 9, 30);

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
  await cargador.load();
}

/// Sin esto `flutter test` pinta el texto con la fuente de bloques Ahem.
Future<void> cargarFuentes() async {
  await _cargarFuente('Manrope', 'assets/fonts/Manrope.ttf');
  await _cargarFuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
  await _cargarFuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}

void prepararPantalla(WidgetTester tester, Size tamano, double escala) {
  ConfiguracionMapa.teselas = false;
  // Densidad 1: las referencias pesan un tercio y alcanzan para detectar
  // una regresión de layout.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamano;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    ConfiguracionMapa.teselas = true;
  });
}

/// Una prueba por tamaño y escala de texto: [montar] deja la pantalla lista
/// y la prueba exige que no haya desbordes ni excepciones de layout; en
/// macOS compara además contra `goldens/<nombre>_<ancho>x<alto>_x<escala>`.
void variantesDePantalla(
  String nombre,
  Future<void> Function(WidgetTester tester) montar,
) {
  for (final tamano in tamanos) {
    for (final escala in escalas) {
      final sufijo =
          '${tamano.width.toInt()}x${tamano.height.toInt()}_x${escala.toInt()}';
      testWidgets('$nombre $sufijo: sin desbordes y golden', (tester) async {
        prepararPantalla(tester, tamano, escala);
        await montar(tester);
        expect(tester.takeException(), isNull);
        if (Platform.isMacOS) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${nombre}_$sufijo.png'),
          );
        }
      });
    }
  }
}

/// Carga en caché una imagen empaquetada para que el golden la pinte.
Future<void> precargar(WidgetTester tester, String asset) async {
  final contexto = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() => precacheImage(AssetImage(asset), contexto));
  await tester.pumpAndSettle();
}
