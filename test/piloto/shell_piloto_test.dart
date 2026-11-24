import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/di/dependencias_negociacion.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

DependenciasPiloto _dependencias() => DependenciasPiloto.demo(
  proveedor: DependenciasProveedor.demo(
    AlmacenDemoProveedor(),
    negociacion: DependenciasNegociacion.demo(
      almacen: AlmacenNegociacionDemo(latencia: Duration.zero),
    ),
  ),
);

void main() {
  Future<void> montar(WidgetTester tester) async {
    prepararTelefono(tester);
    await tester.pumpWidget(AppPilotoDemo(dependencias: _dependencias()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('abre en el mapa de solicitudes abiertas', (tester) async {
    await montar(tester);
    expect(find.text('Solicitudes abiertas'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Valles'), findsOneWidget);
  });

  testWidgets('ofertas, servicio, drones y perfil cargan con datos', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text('Ofertas').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Mis ofertas'), findsOneWidget);
    expect(find.text('Te toca responder'), findsOneWidget);

    await tester.tap(find.text('Servicio').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('En ejecución'), findsOneWidget);
    expect(find.text('Adjudicado'), findsOneWidget);

    await tester.tap(find.text('Drones').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DJI Agras T50'), findsOneWidget);

    await tester.tap(find.text('Perfil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Métricas'), findsOneWidget);
    expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);
  });

  testWidgets(
    'el perfil ofrece los avisos y, en demo, no hay sesión que cerrar',
    (tester) async {
      await montar(tester);
      await tester.tap(find.text('Perfil').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final avisos = find.byKey(const Key('perfil-avisos'));
      await tester.scrollUntilVisible(
        avisos,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(avisos, findsOneWidget);
      expect(find.byKey(const Key('perfil-salir')), findsNothing);
      await Scrollable.ensureVisible(tester.element(avisos), alignment: 0.5);
      await tester.pump();
      await tester.tap(avisos);
      await tester.pumpAndSettle();
      expect(find.text('Nuevas solicitudes'), findsOneWidget);
    },
  );

  testWidgets('la navegación respeta los cinco destinos del piloto', (
    tester,
  ) async {
    await montar(tester);
    for (final etiqueta in [
      'Mapa',
      'Ofertas',
      'Servicio',
      'Drones',
      'Perfil',
    ]) {
      expect(find.text(etiqueta), findsWidgets);
    }
  });
}
