import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

void main() {
  testWidgets('la bandeja muestra ofertas y permite rechazar una', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppPilotoDemo(dependencias: DependenciasPiloto.demo()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ofertas'), findsWidgets);
    expect(find.textContaining('flota de Agrocom'), findsWidgets);
    expect(find.text('3 ofertas vigentes'), findsOneWidget);
  });

  testWidgets('servicio, drones y perfil cargan con datos', (tester) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppPilotoDemo(dependencias: DependenciasPiloto.demo()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Servicio').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('HECTÁREAS CUBIERTAS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Abrir sesión de vuelo'), 300);
    expect(find.text('Abrir sesión de vuelo'), findsOneWidget);

    await tester.tap(find.text('Drones').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DJI Agras T50'), findsOneWidget);

    await tester.tap(find.text('Perfil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hectáreas por mes'), findsOneWidget);
    expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);
  });
}
