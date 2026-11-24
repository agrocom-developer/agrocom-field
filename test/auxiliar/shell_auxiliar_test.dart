import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/auxiliar/app_auxiliar_demo.dart';
import 'package:agrocom_field/auxiliar/di/dependencias_auxiliar.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

void main() {
  Future<void> montar(WidgetTester tester) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('el auxiliar ve el servicio adjudicado de su equipo', (
    tester,
  ) async {
    await montar(tester);
    expect(find.text('Servicio'), findsWidgets);
    expect(find.text('En ejecución'), findsOneWidget);
    expect(find.text('Adjudicado'), findsOneWidget);
  });

  testWidgets('el auxiliar no negocia: no tiene mapa ni ofertas', (
    tester,
  ) async {
    await montar(tester);
    expect(find.text('Mapa'), findsNothing);
    expect(find.text('Ofertas'), findsNothing);
  });

  testWidgets('el auxiliar abre el servicio y no comparte su ubicación', (
    tester,
  ) async {
    await montar(tester);
    await tester.tap(find.text('En ejecución'));
    await tester.pumpAndSettle();
    expect(find.text('Subir foto de avance'), findsOneWidget);
    expect(find.text('Dile al cliente dónde estás'), findsNothing);
  });

  testWidgets('el perfil y los drones del proveedor siguen a mano', (
    tester,
  ) async {
    await montar(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);
    // Sin negociación no hay avisos de nuevas solicitudes.
    expect(find.byKey(const Key('perfil-avisos')), findsNothing);

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
  });
}
