// Vista previa del modo campo (ADR 0008): smoke test de que las cinco
// pantallas mock se montan con los widgets reales del catálogo y que el
// selector superior las alterna. No prueba datos — no los hay: son
// constantes, igual que el mockup de origen.

import 'package:agrocom_field/nucleo/ui/vitrina_campo/vitrina_campo_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('monta la vitrina y alterna entre pantallas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VitrinaCampoPantalla()));
    await tester.pumpAndSettle();

    // 01 · Onboarding arranca seleccionado.
    expect(find.textContaining('La app sí.'), findsOneWidget);

    await tester.tap(find.text('Sync'));
    await tester.pumpAndSettle();
    expect(find.text('Cola de sincronización'), findsOneWidget);
    // La lista es perezosa: solo se afirma sobre lo que entra en el
    // viewport del test (el resumen ámbar y los primeros registros).
    expect(find.text('registros pendientes'), findsOneWidget);
    expect(find.text('PEND'), findsWidgets);

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('LITROS POR HECTÁREA'), findsOneWidget);

    await tester.tap(find.text('Sólido'));
    await tester.pumpAndSettle();
    expect(find.text('KILOS POR VUELO'), findsOneWidget);
    expect(find.text('LITROS POR HECTÁREA'), findsNothing);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Vincular dispositivo'), findsOneWidget);
    expect(find.bySemanticsLabel('Agrocom'), findsOneWidget);
  });

  testWidgets('el botón cerrar vuelve a la pantalla anterior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VitrinaCampoPantalla(),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(VitrinaCampoPantalla), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(VitrinaCampoPantalla), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });
}
