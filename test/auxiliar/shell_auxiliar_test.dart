import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/auxiliar/app_auxiliar_demo.dart';
import 'package:agrocom_field/auxiliar/di/dependencias_auxiliar.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

void main() {
  testWidgets('registrar una carga la suma al total al instante', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CALDO A PREPARAR'), findsOneWidget);

    await tester.tap(find.text('Mezcla').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('264,5 L'), findsOneWidget);

    await tester.tap(find.text('Registrar carga'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.text('Registrar carga').last);
    await tester.pumpAndSettle();
    expect(find.text('314,5 L'), findsOneWidget);
  });

  testWidgets(
    'el auxiliar ve la bandeja, el perfil y los drones del proveedor',
    (tester) async {
      prepararTelefono(tester);
      await tester.pumpWidget(
        AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Ofertas').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('3 ofertas vigentes'), findsOneWidget);

      await tester.tap(find.text('Perfil').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);

      final drones = find.byKey(const Key('perfil-ver-drones'));
      await tester.scrollUntilVisible(
        drones,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(drones), alignment: 0.5);
      await tester.pump();
      await tester.tap(drones);
      await tester.pumpAndSettle();
      expect(find.text('Mis drones'), findsOneWidget);
      expect(find.text('DJI Agras T50'), findsOneWidget);
    },
  );
}
