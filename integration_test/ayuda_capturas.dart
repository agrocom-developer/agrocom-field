// Ayudas de las pruebas de captura de QA visual (ver `test_driver/`).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

IntegrationTestWidgetsFlutterBinding get binding =>
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// Avanza el reloj [ms] milisegundos en pasos de 100 ms. No usa
/// `pumpAndSettle`: el radar y el esqueleto animan en bucle.
Future<void> esperar(WidgetTester t, [int ms = 800]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Captura la pantalla con el nombre dado, tras dejar asentar las animaciones.
Future<void> captura(WidgetTester t, String nombre, {int ms = 900}) async {
  await esperar(t, ms);
  // El simulador comparte el sistema de archivos con el Mac: la prueba deja
  // un pedido y espera a que `tool/capturar_pantallas.sh` escriba el PNG con
  // `xcrun simctl io screenshot`, para que la captura corresponda a esta
  // pantalla y no a una posterior.
  const dir = String.fromEnvironment('CAPTURAS_DIR');
  const sufijo = String.fromEnvironment('CAPTURAS_SUFIJO');
  if (dir.isEmpty) return;
  final archivo = File('$dir/$nombre${sufijo.isEmpty ? '' : '_$sufijo'}.png');
  if (archivo.existsSync()) archivo.deleteSync();
  File('$dir/pedido_$nombre.txt').writeAsStringSync(archivo.path);
  for (var i = 0; i < 300 && !archivo.existsSync(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));
}

/// Ejecuta [accion] sin abortar la corrida si falla: la captura continúa y
/// el fallo queda impreso para el informe.
Future<void> paso(String nombre, Future<void> Function() accion) async {
  try {
    await accion();
  } catch (e) {
    final resumen = '$nombre: ${e.toString().split('\n').first}';
    pasosFallidos.add(resumen);
    debugPrint('PASO FALLIDO [$resumen]');
  }
}

/// Pasos que fallaron en la corrida; los recorridos conectados los revisan
/// al final para que un paso roto no pase por verde.
final List<String> pasosFallidos = [];

Future<void> tocar(WidgetTester t, Finder f, {int ms = 600}) async {
  if (f.evaluate().isEmpty) {
    // Listas perezosas: el elemento aún no se construyó; se baja hasta él.
    await t.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(f.first);
  await t.pump(const Duration(milliseconds: 100));
  await t.tap(f.first, warnIfMissed: false);
  await esperar(t, ms);
}

/// Primer widget cuya `ValueKey`/`Key` de texto empieza con [prefijo].
Finder porPrefijo(String prefijo) => find.byWidgetPredicate((w) {
  final k = w.key;
  if (k is ValueKey) return k.value.toString().startsWith(prefijo);
  return false;
});

/// Baja el desplazable principal [px] píxeles.
Future<void> bajar(WidgetTester t, double px) async {
  final s = find.byType(Scrollable);
  if (s.evaluate().isEmpty) return;
  await t.drag(s.first, Offset(0, -px));
  await esperar(t, 500);
}

Future<void> atras(WidgetTester t) async {
  final f = find.byType(BackButton);
  if (f.evaluate().isNotEmpty) {
    await tocar(t, f);
  } else {
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    await nav.maybePop();
    await esperar(t);
  }
}

/// Escribe [texto] en [campo] y cierra el teclado, para que no tape los
/// controles que siguen ni la captura.
Future<void> escribir(WidgetTester t, Finder campo, String texto) async {
  await t.enterText(campo, texto);
  await esperar(t, 200);
  FocusManager.instance.primaryFocus?.unfocus();
  await esperar(t, 500);
}
