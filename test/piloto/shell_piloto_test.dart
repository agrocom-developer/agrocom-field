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
    expect(find.text('Buscar zona o lote'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Valles'), findsOneWidget);
  });

  testWidgets(
    'ofertas, servicios y perfil cargan con datos; el dron se abre desde el perfil',
    (tester) async {
      await montar(tester);

      await tester.tap(find.text('Ofertas').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mis ofertas'), findsOneWidget);
      expect(find.text('Tu turno · R4/5'), findsOneWidget);

      await tester.tap(find.text('Servicios').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('En ejecución'), findsOneWidget);
      expect(find.text('Adjudicado'), findsOneWidget);

      await tester.tap(find.text('Perfil').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Métricas'), findsOneWidget);
      expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);

      // El dron y la licencia viven en el perfil.
      final dron = find.byKey(const Key('perfil-ver-drones'));
      await tester.scrollUntilVisible(
        dron,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(dron);
      await tester.pump();
      await tester.tap(dron);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Mis drones'), findsOneWidget);
      expect(find.text('DJI Agras T50'), findsOneWidget);
    },
  );

  testWidgets('el perfil ofrece los avisos', (tester) async {
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
    await Scrollable.ensureVisible(tester.element(avisos), alignment: 0.5);
    await tester.pump();
    await tester.tap(avisos);
    await tester.pumpAndSettle();
    expect(find.text('Nuevas solicitudes'), findsOneWidget);
  });

  testWidgets('la navegación tiene los cuatro destinos del piloto', (
    tester,
  ) async {
    await montar(tester);
    for (final etiqueta in ['Mapa', 'Ofertas', 'Servicios', 'Perfil']) {
      expect(find.text(etiqueta), findsWidgets);
    }
    expect(find.text('Drones'), findsNothing);
  });

  testWidgets('cerrar sesión está en el menú del perfil y en Ajustes (demo)', (
    tester,
  ) async {
    await montar(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('perfil-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    final ajustes = find.byKey(const Key('perfil-ajustes'));
    await tester.scrollUntilVisible(
      ajustes,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(ajustes), alignment: 0.5);
    await tester.pump();
    await tester.tap(ajustes);
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ajustes-confirmar-salida')));
    await tester.pumpAndSettle();
    // La demo vuelve al inicio: el mapa de solicitudes.
    expect(find.text('Buscar zona o lote'), findsOneWidget);
  });

  testWidgets('el perfil ya no muestra el selector de tema (vive en Ajustes)', (
    tester,
  ) async {
    await montar(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Oscuro'), findsNothing);
    expect(find.byKey(const Key('perfil-tema')), findsNothing);
  });
}
