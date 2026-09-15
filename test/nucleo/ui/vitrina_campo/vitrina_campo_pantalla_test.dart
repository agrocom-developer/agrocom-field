// Vista previa del modo campo (ADR 0008): smoke test de que las pantallas
// mock se montan con los widgets reales del catálogo, que el selector
// superior (desplazable, nueve pestañas) las alterna, y que las ajustadas al
// contrato de `agrocom-api` muestran sus campos reales. No prueba datos —
// no los hay: son constantes, igual que el mockup de origen.

import 'package:agrocom_field/nucleo/ui/vitrina_campo/vitrina_campo_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cambia de pestaña: el selector se desplaza horizontalmente, así que la
/// pestaña puede estar fuera del viewport del test antes de tocarla.
Future<void> _ir(WidgetTester tester, String pestana) async {
  await tester.ensureVisible(find.text(pestana));
  await tester.tap(find.text(pestana));
  await tester.pumpAndSettle();
}

/// Las pantallas usan `ListView` perezosos: lo que queda debajo del viewport
/// del test no se construye hasta hacerle scroll.
Future<void> _verHasta(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView),
    const Offset(0, -160),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('monta la vitrina y alterna entre pantallas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VitrinaCampoPantalla()));
    await tester.pumpAndSettle();

    // 01 · Onboarding arranca seleccionado.
    expect(find.textContaining('La app sí.'), findsOneWidget);

    await _ir(tester, 'Sync');
    expect(find.text('Cola de sincronización'), findsOneWidget);
    expect(find.text('registros pendientes'), findsOneWidget);
    expect(find.text('PEND'), findsWidgets);

    await _ir(tester, 'Crear');
    expect(find.text('LITROS POR HECTÁREA'), findsOneWidget);
    await tester.tap(find.text('Sólido'));
    await tester.pumpAndSettle();
    expect(find.text('KILOS POR VUELO'), findsOneWidget);
    expect(find.text('LITROS POR HECTÁREA'), findsNothing);

    await _ir(tester, 'Login');
    expect(find.text('Vincular dispositivo'), findsOneWidget);
    expect(find.bySemanticsLabel('Agrocom'), findsOneWidget);

    await _ir(tester, 'Inicio B');
    expect(find.text('Iniciar aplicación'), findsOneWidget);
  });

  testWidgets(
    'las pantallas ajustadas al contrato muestran sus campos reales',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VitrinaCampoPantalla()));
      await tester.pumpAndSettle();

      // 06 · condiciones: fuera de rango exige observación y firma.
      await _ir(tester, 'Clima');
      expect(find.text('Guardar condiciones'), findsOneWidget);
      expect(find.text('Apto para aplicar'), findsOneWidget);
      await tester.tap(find.text('Fuera de rango'));
      await tester.pumpAndSettle();
      expect(find.text('Apto para aplicar'), findsNothing);
      await _verHasta(tester, find.text('OBSERVACIÓN DEL AGRÓNOMO'));
      await _verHasta(tester, find.text('FIRMA (TEXTO PLANO)'));

      // 07 · evidencia_equipo: horas de vuelo + tres fotos obligatorias.
      await _ir(tester, 'Equipos');
      expect(find.text('HORAS DE VUELO DEL DRON'), findsOneWidget);
      expect(find.text('Cerrar reporte'), findsOneWidget);
      await _verHasta(tester, find.text('dron limpio'));

      // 08 · OrdenCatalogo: lotes de HU-92 y CTA real de HU-05.
      await _ir(tester, 'Orden');
      expect(find.text('Abrir trabajo'), findsOneWidget);
      await _verHasta(tester, find.text('Lotes de la orden'));

      // 04 · sin pH: la orden trae litros_ha o kilos_por_vuelo (HU-79).
      await _ir(tester, 'Crear');
      expect(find.text('PH AGUA', skipOffstage: false), findsNothing);
      await _verHasta(tester, find.text('HECTÁREAS DECLARADAS'));
    },
  );

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
