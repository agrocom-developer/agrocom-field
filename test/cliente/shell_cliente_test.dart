import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

void main() {
  testWidgets('el inicio muestra el servicio en curso y el por calificar', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, Hugo'), findsOneWidget);
    expect(find.text('Solicitar un servicio'), findsOneWidget);
    expect(find.text('Seguir en vivo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Calificar'), 300);
    expect(find.text('Calificar'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('solicitar un servicio en tres pasos lo agrega al historial', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicitar').last);
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3 · Dónde'), findsOneWidget);

    await tester.tap(find.text('Maíz La Curva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 3 · Qué'), findsOneWidget);

    await tester.tap(find.text('Insecticida piretroide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 3 · Cuándo'), findsOneWidget);
    expect(find.text('Bs 7.695'), findsOneWidget);

    final fecha = find.byType(ChoiceChip).first;
    await tester.tap(fecha);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solicitar servicio').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Servicio'), findsWidgets);
    expect(find.text('Buscando proveedor'), findsWidgets);
  });

  testWidgets('en iPad la navegación pasa a riel lateral', (tester) async {
    prepararIpad(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('las pestañas Servicios y Cuenta cargan sus datos', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    expect(find.text('Mis servicios'), findsOneWidget);
    await tester.tap(find.text('Cuenta').last);
    await tester.pumpAndSettle();
    expect(find.text('Hugo Antelo Suárez'), findsOneWidget);
  });
}
