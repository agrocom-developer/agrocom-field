// Etapa 2 de HU-68: `EmergenciaBoton` con un fake de `LinternaControlador`
// (mocktail) — sin canal de plataforma real. La integración con `AgrocomApp`
// (visible sobre login, ausente en piloto) ya está cubierta en
// `test/app_test.dart`; acá se prueba el widget en aislamiento.

import 'package:agrocom_field/features/emergencia/presentation/emergencia_boton.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/linterna/linterna_controlador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _LinternaControladorFalso extends Mock implements LinternaControlador {}

Widget _envolver(Widget child) => MaterialApp(home: child);

void main() {
  late _LinternaControladorFalso linterna;

  setUp(() {
    linterna = _LinternaControladorFalso();
    when(() => linterna.disponible()).thenAnswer((_) async => true);
    when(() => linterna.encender()).thenAnswer((_) async {});
    when(() => linterna.apagar()).thenAnswer((_) async {});
  });

  testWidgets('en piloto no monta el botón, solo el contenido', (tester) async {
    await tester.pumpWidget(
      _envolver(
        EmergenciaBoton(
          flavor: Flavor.piloto,
          linternaControlador: linterna,
          child: const Text('contenido'),
        ),
      ),
    );

    expect(find.text('contenido'), findsOneWidget);
    expect(find.byKey(const Key('emergencia_boton')), findsNothing);
  });

  testWidgets(
    'en auxiliar monta el botón sobre el contenido y abre el panel al tocarlo',
    (tester) async {
      await tester.pumpWidget(
        _envolver(
          EmergenciaBoton(
            flavor: Flavor.auxiliar,
            linternaControlador: linterna,
            child: const Text('contenido'),
          ),
        ),
      );

      expect(find.text('contenido'), findsOneWidget);
      expect(find.byKey(const Key('emergencia_boton')), findsOneWidget);
      expect(find.byKey(const Key('linterna_switch')), findsNothing);

      await tester.tap(find.byKey(const Key('emergencia_boton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('linterna_switch')), findsOneWidget);
    },
  );

  testWidgets('el switch de linterna llama al controlador y refleja estado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        EmergenciaBoton(
          flavor: Flavor.auxiliar,
          linternaControlador: linterna,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('emergencia_boton')));
    await tester.pumpAndSettle();

    expect(find.text('Apagada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('linterna_switch')));
    await tester.pumpAndSettle();

    verify(() => linterna.encender()).called(1);
    expect(find.text('Encendida'), findsOneWidget);
    verifyNever(() => linterna.apagar());

    await tester.tap(find.byKey(const Key('linterna_switch')));
    await tester.pumpAndSettle();

    verify(() => linterna.apagar()).called(1);
    expect(find.text('Apagada'), findsOneWidget);
  });

  testWidgets(
    'si la linterna no está disponible, el switch queda deshabilitado',
    (tester) async {
      when(() => linterna.disponible()).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _envolver(
          EmergenciaBoton(
            flavor: Flavor.auxiliar,
            linternaControlador: linterna,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('emergencia_boton')));
      await tester.pumpAndSettle();

      expect(find.text('No disponible en este dispositivo'), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('linterna_switch')),
      );
      expect(switchTile.onChanged, isNull);
    },
  );
}
