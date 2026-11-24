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

  testWidgets('solicitar un servicio en cuatro pasos lo agrega al historial', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo()),
    );
    await tester.pumpAndSettle();

    Future<void> tocar(Finder objetivo) async {
      await tester.scrollUntilVisible(
        objetivo,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(objetivo);
      await tester.pumpAndSettle();
      await tester.tap(objetivo);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Solicitar').last);
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 4 · Lote'), findsOneWidget);

    await tocar(find.text('Maíz La Curva'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 4 · Aplicación'), findsOneWidget);

    await tocar(find.text('Insecticida piretroide'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 4 · Cuándo'), findsOneWidget);

    // El tercer día ofrecido: sin recargo por urgencia.
    await tester.tap(find.byKey(const ValueKey('fecha-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 4 de 4 · Resumen'), findsOneWidget);
    expect(find.text('Bs 7.695'), findsWidgets);

    await tester.tap(find.text('Confirmar solicitud'));
    // La búsqueda de proveedor anima en bucle: se avanza el reloj a mano.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Buscando proveedor'), findsOneWidget);
    expect(find.text('1. Pilotos de Agrocom'), findsOneWidget);

    // Dos rondas de la demo (propios, terceros) y un proveedor acepta.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Proveedor asignado'), findsOneWidget);

    await tester.tap(find.text('Ver el servicio'));
    await tester.pumpAndSettle();
    expect(find.text('Servicio'), findsWidgets);
    expect(find.text('Proveedor asignado'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hola, Hugo'), findsOneWidget);
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
