// Mapa de solicitudes, negociación y mis ofertas del piloto en los tres
// modos visuales (claro, oscuro y campo AAA), a ancho de teléfono pequeño
// (360) y grande (412), con la fuente real. Los goldens solo corren en macOS.

import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/negociacion_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/l10n/app_localizations.dart';

import 'ayudas.dart';

void main() {
  setUpAll(cargarFuentes);

  late EntornoNegociacion entorno;
  setUp(() => entorno = EntornoNegociacion());

  Future<void> montarEn(
    WidgetTester tester,
    Widget pantalla,
    ModoVisualCampo modo,
    Size tamano,
  ) async {
    ConfiguracionMapa.teselas = false;
    tester.view.physicalSize = tamano * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      ConfiguracionMapa.teselas = true;
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        debugShowCheckedModeBanner: false,
        theme: AgrocomThemeCampo.construir(modo: modo),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: entorno.dependencias.proveer(child: child!),
        ),
        home: Scaffold(body: SafeArea(child: pantalla)),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  final pantallas = <String, Widget Function()>{
    'mapa': () => MapaSolicitudesPantalla(reloj: relojFijo),
    'negociacion': () => const NegociacionPantalla(solicitudId: 4),
    'mis_ofertas': () => const MisOfertasPantalla(),
  };

  for (final modo in ModoVisualCampo.values) {
    for (final tamano in [telefonoChico, telefonoGrande]) {
      for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
        testWidgets('$nombre en ${modo.name} a ${tamano.width.toInt()}', (
          tester,
        ) async {
          await montarEn(tester, pantalla(), modo, tamano);
          expect(tester.takeException(), isNull);
          await golden(
            tester,
            'modos_${nombre}_${modo.name}_${tamano.width.toInt()}',
          );
        });
      }
    }
  }
}
