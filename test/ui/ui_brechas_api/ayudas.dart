// Ayudas de las pruebas de UI de las pantallas de las rutas nuevas de la API
// (precio de referencia, foto de perfil, fotos de terreno, pago confirmado):
// fuentes reales, matriz de tamaños, modos claro, oscuro y campo.

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// El render de texto difiere entre macOS y Linux: los goldens de referencia
/// se generan en macOS y en CI (Linux) se omiten.
final String? saltarGolden = Platform.isMacOS
    ? null
    : 'golden de referencia generado en macOS';

class Variante {
  const Variante(this.nombre, this.modo, this.tamano, this.escala);

  final String nombre;
  final ModoVisualCampo modo;
  final Size tamano;
  final double escala;
}

const chico = Size(360, 640);
const grande = Size(412, 915);

/// Claro en chico y grande, oscuro en grande y el chico con el texto al 200 %.
const matrizCliente = [
  Variante('claro_360', ModoVisualCampo.claro, chico, 1),
  Variante('claro_412', ModoVisualCampo.claro, grande, 1),
  Variante('oscuro_412', ModoVisualCampo.oscuro, grande, 1),
  Variante('claro_360_texto200', ModoVisualCampo.claro, chico, 2),
];

/// El modo campo (alto contraste) de piloto y auxiliar.
const matrizCampo = [
  Variante('campo_360', ModoVisualCampo.campo, chico, 1),
  Variante('campo_412', ModoVisualCampo.campo, grande, 1),
  Variante('campo_360_texto200', ModoVisualCampo.campo, chico, 2),
];

Future<void> cargarFuentes() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> fuente(String familia, String ruta) async {
    final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
    await cargador.load();
  }

  await fuente('Manrope', 'assets/fonts/Manrope.ttf');
  await fuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
  await fuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}

/// Monta [hijo] en una pantalla con el tema del modo y los [repositorios]
/// arriba del `Navigator`, y movimiento reducido (sin animaciones sueltas).
Future<void> montar(
  WidgetTester tester,
  Widget hijo, {
  Variante variante = const Variante(
    'claro_412',
    ModoVisualCampo.claro,
    grande,
    1,
  ),
  List<RepositoryProvider<Object>> repositorios = const [],
  bool conScaffold = true,
}) async {
  tester.view.physicalSize = variante.tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget home = conScaffold
      ? Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: hijo,
            ),
          ),
        )
      : hijo;
  if (repositorios.isNotEmpty) {
    home = MultiRepositoryProvider(providers: repositorios, child: home);
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(modo: variante.modo),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(variante.escala),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Deja pasar cargas sin latencia. No usa `pumpAndSettle`: el esqueleto de
/// carga no se detiene solo.
Future<void> asentar(WidgetTester tester, {int veces = 5}) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> golden(WidgetTester tester, String nombre) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$nombre.png'),
);
