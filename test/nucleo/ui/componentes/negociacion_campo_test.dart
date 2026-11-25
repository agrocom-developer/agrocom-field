// Componentes de negociación de la identidad Industrial AgTech: comportamiento
// y goldens de la vitrina en claro, oscuro y campo, a ancho de teléfono
// pequeño (360) y grande (412).
//
// Los goldens se regeneran con `flutter test --update-goldens` y solo corren
// en macOS (el render de texto difiere en Linux).

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/vitrina_campo/negociacion_campo_vitrina.dart';
import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
  await cargador.load();
}

Widget _envolver(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  debugShowCheckedModeBanner: false,
  theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
  home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _cargarFuente('Manrope', 'assets/fonts/Manrope.ttf');
    await _cargarFuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await _cargarFuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  group('StepperCampo', () {
    testWidgets('suma y resta de uno en uno y respeta los límites', (
      tester,
    ) async {
      var valor = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _envolver(
            StepperCampo(
              valor: valor,
              minimo: 1,
              maximo: 2,
              etiqueta: 'Ronda',
              onCambio: (v) => setState(() => valor = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(valor, 1);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(valor, 2);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(valor, 2);
    });

    testWidgets('los botones miden 56, y 72 en campo', (tester) async {
      await tester.pumpWidget(
        _envolver(StepperCampo(valor: 2, etiqueta: 'Ronda', onCambio: (_) {})),
      );
      final boton = find.ancestor(
        of: find.byIcon(Icons.add_rounded),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(boton.first).height, 56);
      await tester.pumpWidget(
        _envolver(
          StepperCampo(
            valor: 2,
            etiqueta: 'Ronda',
            alturaCampo: true,
            onCambio: (_) {},
          ),
        ),
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byIcon(Icons.add_rounded),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .height,
        72,
      );
    });
  });

  testWidgets('la burbuja anuncia ronda, autor, precio y turno', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      _envolver(
        const BurbujaNegociacionCampo(
          autor: AutorRonda.piloto,
          ronda: 2,
          precioPorHectarea: '95',
          total: '8.550',
          esTurno: true,
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('Ronda 2 de 5, piloto: 95 bolivianos')),
      findsOneWidget,
    );
    expect(find.text('R2 · PILOTO'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el banner sin señal lleva el prefijo y avisa al lector', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(const BannerSinSenalCampo(mensaje: 'se guarda en cola.')),
    );
    expect(find.text('Sin señal · se guarda en cola.'), findsOneWidget);
  });

  testWidgets('el post-it elegido muestra la insignia', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const PostItOfertaCampo(
          piloto: 'Rubén M.',
          precioPorHectarea: '85',
          total: '7.650',
          elegido: true,
        ),
      ),
    );
    expect(find.text('ELEGIDO'), findsOneWidget);
  });

  testWidgets('la hoja inferior se abre y muestra su contenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => mostrarHojaInferiorCampo<void>(
              context: context,
              builder: (_) => const Text('Contenido de la hoja'),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido de la hoja'), findsOneWidget);
    expect(find.byType(HojaInferiorCampo), findsOneWidget);
  });

  final saltar = !Platform.isMacOS;
  for (final modo in ModoVisualCampo.values) {
    for (final ancho in [360.0, 412.0]) {
      testWidgets(
        'golden de la vitrina de negociación, ${modo.name} $ancho',
        skip: saltar,
        (tester) async {
          tester.view.physicalSize = Size(ancho, 2450) * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              debugShowCheckedModeBanner: false,
              theme: AgrocomThemeCampo.construir(modo: modo),
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Scaffold(body: NegociacionCampoVitrina(modo: modo)),
              ),
            ),
          );
          // Deja decodificar las fotos de assets (corren fuera del reloj falso).
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await tester.pump();
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../goldens/negociacion_${modo.name}_${ancho.toInt()}.png',
            ),
          );
        },
      );
    }
  }
}
