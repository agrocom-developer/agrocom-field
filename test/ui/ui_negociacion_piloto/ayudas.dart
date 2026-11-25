// Ayudas de las pruebas de UI de la negociación del piloto: fuentes reales,
// reloj fijo, dependencias demo sin espera y un montaje con el tema de modo
// campo en los tamaños de teléfono que exige el sistema visual.

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/data/ejecucion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/di/dependencias_ejecucion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/di/dependencias_negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/l10n/app_localizations.dart';

/// Los goldens se generan y se comparan en macOS; en otras plataformas la
/// prueba solo monta cada pantalla (un desborde de layout la hace fallar).
final bool conGoldens = Platform.isMacOS;

const telefonoChico = Size(360, 640);
const telefonoGrande = Size(412, 915);

/// Las cuatro combinaciones que exige el sistema visual (§11).
const matriz = [
  (telefonoChico, 1.0),
  (telefonoChico, 2.0),
  (telefonoGrande, 1.0),
  (telefonoGrande, 2.0),
];

String sufijo(Size t, double escala) =>
    '${t.width.toInt()}x${t.height.toInt()}_x${escala.toInt()}';

DateTime relojFijo() => DateTime(2026, 11, 24, 9);

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

/// Dependencias demo con reloj fijo y sin espera simulada.
class EntornoNegociacion {
  EntornoNegociacion({
    EjecucionDemo? ejecucion,
    ServicioUbicacionDemo? gps,
    SelectorFoto? camara,
    bool compartirUbicacion = true,
  }) : almacenNegociacion = AlmacenNegociacionDemo(
         reloj: relojFijo,
         latencia: Duration.zero,
       ),
       ejecucionDemo = ejecucion ?? EjecucionDemo(reloj: relojFijo),
       ubicacionDemo = gps ?? ServicioUbicacionDemo(),
       publicador = UbicacionDemo() {
    final almacen = AlmacenDemoProveedor(datos: DatosDemo(reloj: relojFijo));
    dependencias = DependenciasProveedor.demo(
      almacen,
      negociacion: DependenciasNegociacion.demo(almacen: almacenNegociacion),
      ejecucion: DependenciasEjecucion.demo(
        repositorio: ejecucionDemo,
        ubicacion: ubicacionDemo,
        publicador: publicador,
        selectorFoto: camara,
        compartirUbicacion: compartirUbicacion,
      ),
    );
  }

  final AlmacenNegociacionDemo almacenNegociacion;
  final EjecucionDemo ejecucionDemo;
  final ServicioUbicacionDemo ubicacionDemo;
  final UbicacionDemo publicador;
  late final DependenciasProveedor dependencias;
}

/// Monta [pantalla] con el tema de modo campo, como en el shell del flavor.
Future<void> montar(
  WidgetTester tester,
  Widget pantalla, {
  required DependenciasProveedor dependencias,
  Size tamano = telefonoGrande,
  double escala = 1.0,
  bool envolverEnScaffold = true,
  List<Widget Function(Widget)> envoltorios = const [],
}) async {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = tamano * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    ConfiguracionMapa.teselas = true;
  });
  Widget home = envolverEnScaffold
      ? Scaffold(body: SafeArea(child: pantalla))
      : pantalla;
  for (final e in envoltorios) {
    home = e(home);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
          disableAnimations: true,
        ),
        child: dependencias.proveer(child: child!),
      ),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> golden(WidgetTester tester, String nombre) async {
  if (!conGoldens) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$nombre.png'),
  );
}

/// Lleva [destino] a la vista y lo centra para que un toque le pegue.
Future<void> irA(WidgetTester tester, Finder destino) async {
  await tester.scrollUntilVisible(
    destino,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(destino), alignment: 0.5);
  await tester.pump();
}
