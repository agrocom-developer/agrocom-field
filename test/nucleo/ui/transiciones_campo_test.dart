import 'package:agrocom_field/nucleo/ui/transiciones_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TransicionesCampo.detalle apila la página nueva', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                TransicionesCampo.detalle<void>(
                  (_) => const Scaffold(body: Text('Detalle')),
                ),
              ),
              child: const Text('Abrir detalle'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle'), findsOneWidget);
  });

  testWidgets('TransicionesCampo.modal apila la página nueva', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                TransicionesCampo.modal<void>(
                  (_) => const Scaffold(body: Text('Modal')),
                ),
              ),
              child: const Text('Abrir modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir modal'));
    await tester.pumpAndSettle();
    expect(find.text('Modal'), findsOneWidget);
  });

  testWidgets(
    'con "reducir movimiento" la página nueva igual se apila, sin lanzar errores',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    TransicionesCampo.detalle<void>(
                      (_) => const Scaffold(body: Text('Detalle')),
                    ),
                  ),
                  child: const Text('Abrir detalle'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir detalle'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
