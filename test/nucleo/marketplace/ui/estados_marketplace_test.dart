import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/estado_error_marketplace.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/estado_vacio_marketplace.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

Future<void> _montar(
  WidgetTester tester,
  Widget cuerpo, {
  ModoVisualCampo modo = ModoVisualCampo.claro,
  Size tamano = const Size(360, 640),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(modo: modo),
      home: Scaffold(body: cuerpo),
    ),
  );
  await tester.pump();
}

void main() {
  group('estado vacío (20)', () {
    testWidgets('ícono en contenedor de 88, título, texto y acción', (
      tester,
    ) async {
      var tocado = false;
      await _montar(
        tester,
        EstadoVacioMarketplace(
          icono: Icons.map_outlined,
          titulo: 'Todavía no enviaste ofertas',
          detalle: 'Hay 14 lotes abiertos.',
          etiquetaAccion: 'Ver lotes en el mapa',
          alAccion: () => tocado = true,
        ),
      );
      final contenedor = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == EstadoVacioMarketplace.ladoContenedor,
      );
      expect(contenedor, findsOneWidget);
      expect(find.text('Hay 14 lotes abiertos.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('estado-vacio-accion')));
      expect(tocado, isTrue);
    });

    testWidgets('sin acción no hay botón y con texto al 200 % no desborda', (
      tester,
    ) async {
      await _montar(
        tester,
        const EstadoVacioMarketplace(
          icono: Icons.inbox_outlined,
          titulo: 'Todavía no hay mensajes',
          detalle: 'Escríbele al piloto para coordinar el día de la visita.',
        ),
        escala: 2,
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('error de envío o de carga (21)', () {
    testWidgets('sin red: banner, tabla, reintentar y salida alterna', (
      tester,
    ) async {
      var reintentos = 0;
      var volvio = false;
      await _montar(
        tester,
        EstadoErrorMarketplace(
          sinConexion: true,
          tablaSinRed: true,
          titulo: 'No se envió tu contraoferta',
          detalle: 'Quedó guardada.',
          onReintentar: () => reintentos++,
          etiquetaSecundaria: 'Volver a la negociación',
          onSecundaria: () => volvio = true,
        ),
      );
      expect(find.textContaining('Sin señal'), findsOneWidget);
      expect(find.byKey(const ValueKey('tabla-sin-red')), findsOneWidget);
      expect(find.text('Funcionan sin red'), findsOneWidget);
      expect(find.text('Requieren red'), findsOneWidget);
      await tester.tap(find.text('Reintentar ahora'));
      await tester.tap(find.text('Volver a la negociación'));
      expect(reintentos, 1);
      expect(volvio, isTrue);
    });

    testWidgets('un error con red no muestra banner ni tabla', (tester) async {
      await _montar(
        tester,
        EstadoErrorMarketplace(
          titulo: 'Algo salió mal',
          detalle: 'Prueba de nuevo.',
          onReintentar: () {},
        ),
      );
      expect(find.textContaining('Sin señal'), findsNothing);
      expect(find.byKey(const ValueKey('tabla-sin-red')), findsNothing);
      expect(find.text('Reintentar ahora'), findsOneWidget);
    });

    testWidgets('dentro de una lista (alto sin tope) se muestra completo', (
      tester,
    ) async {
      await _montar(
        tester,
        ListView(
          children: [
            EstadoErrorMarketplace(
              sinConexion: true,
              tablaSinRed: true,
              titulo: 'Sin conexión',
              onReintentar: () {},
            ),
          ],
        ),
      );
      expect(find.text('Reintentar ahora'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compacto no repite el banner de la pantalla', (tester) async {
      await _montar(
        tester,
        EstadoErrorMarketplace(
          sinConexion: true,
          tablaSinRed: true,
          compacto: true,
          titulo: 'Sin conexión',
          onReintentar: () {},
        ),
      );
      expect(find.textContaining('Sin señal'), findsNothing);
      expect(find.byKey(const ValueKey('tabla-sin-red')), findsNothing);
    });

    for (final modo in ModoVisualCampo.values) {
      testWidgets('se lee en ${modo.name} con texto al 200 %', (tester) async {
        await _montar(
          tester,
          EstadoErrorMarketplace(
            sinConexion: true,
            tablaSinRed: true,
            titulo: 'No se envió tu contraoferta',
            detalle: 'Tu oferta quedó guardada y se envía sola.',
            onReintentar: () {},
            etiquetaSecundaria: 'Volver a la negociación',
            onSecundaria: () {},
          ),
          modo: modo,
          escala: 2,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
