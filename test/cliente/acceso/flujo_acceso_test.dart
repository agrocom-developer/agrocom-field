// Recorrido de acceso del cliente de punta a punta, con la app real y
// repositorios demo sin latencia.

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/presentation/splash_pantalla.dart';
import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../nucleo/marketplace/ayudas_prueba.dart';
import '../dobles_cliente.dart';

Future<void> _abrir(
  WidgetTester tester, {
  bool primerUso = true,
  String? nota,
}) async {
  await tester.pumpWidget(
    AppCliente(
      dependencias: dependenciasDePrueba(
        primerUso: primerUso,
        notaAcceso: nota,
      ),
    ),
  );
}

Future<void> _saltarPresentacion(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding-saltar')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la splash se ve al abrir y da paso a la presentación', (
    tester,
  ) async {
    prepararTelefono(tester);
    await _abrir(tester);
    expect(find.byType(SplashPantalla), findsOneWidget);
    expect(find.byType(LogoAgrocomCampo), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(SplashPantalla), findsNothing);
    expect(find.text('Publica tu lote en el mapa'), findsOneWidget);
  });

  testWidgets('con movimiento reducido la splash no espera la animación', (
    tester,
  ) async {
    prepararTelefono(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _abrir(tester);
    await tester.pump();
    await tester.pump();
    expect(find.byType(SplashPantalla), findsNothing);
    expect(find.text('Publica tu lote en el mapa'), findsOneWidget);
  });

  testWidgets(
    'las portadas recorren tres pantallas y Comenzar abre el registro',
    (tester) async {
      prepararTelefono(tester);
      await _abrir(tester);
      await tester.pumpAndSettle();

      expect(find.text('Publica tu lote en el mapa'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-punto-1')));
      await tester.pumpAndSettle();
      expect(find.text('Negocia hasta 5 rondas'), findsOneWidget);

      // También se avanza y se retrocede deslizando.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Pagas lo que se fumigó'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Negocia hasta 5 rondas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-continuar')));
      await tester.pumpAndSettle();
      expect(find.text('Crea tu cuenta'), findsOneWidget);
    },
  );

  testWidgets('Ya tengo cuenta abre el ingreso', (tester) async {
    prepararTelefono(tester);
    await _abrir(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-tengo-cuenta')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
  });

  testWidgets('ingresar valida en línea y entra al inicio', (tester) async {
    prepararTelefono(tester);
    await _abrir(tester, nota: 'Nota de entorno');
    await _saltarPresentacion(tester);
    expect(find.text('Nota de entorno'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-ingresar')));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu usuario'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Usuario'), 'ana finca');
    await tester.pumpAndSettle();
    expect(
      find.text('Usa de 3 a 40 letras, números, punto o guion'),
      findsOneWidget,
    );

    await tester.enterText(find.bySemanticsLabel('Usuario'), 'ana.finca');
    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'segura123');
    await tester.tap(find.byKey(const Key('login-ingresar')));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Hugo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Ingresa a tu cuenta'), findsNothing);
  });

  testWidgets('un fallo de ingreso se explica y conserva lo escrito', (
    tester,
  ) async {
    prepararTelefono(tester);
    await _abrir(tester);
    await _saltarPresentacion(tester);

    await tester.enterText(find.bySemanticsLabel('Usuario'), 'ana.finca');
    await tester.enterText(
      find.bySemanticsLabel('Contraseña'),
      AccesoDemo.contrasenaIncorrecta,
    );
    await tester.tap(find.byKey(const Key('login-ingresar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('no coinciden'), findsOneWidget);
    expect(find.text('ana.finca'), findsOneWidget);

    // Al corregir, el aviso se retira.
    await tester.enterText(
      find.bySemanticsLabel('Usuario'),
      AccesoDemo.usuarioSinConexion,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('no coinciden'), findsNothing);

    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'segura123');
    await tester.tap(find.byKey(const Key('login-ingresar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(find.text(AccesoDemo.usuarioSinConexion), findsOneWidget);
  });

  testWidgets('registrarse muestra el error del servidor junto al campo y '
      'después entra con el nombre escrito', (tester) async {
    prepararTelefono(tester);
    await _abrir(tester);
    await _saltarPresentacion(tester);

    await tester.tap(find.byKey(const Key('login-crear-cuenta')));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    // Volver regresa al ingreso sin apilar rutas.
    await tester.tap(find.byKey(const Key('registro-volver')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-crear-cuenta')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Nombre completo'),
      'Ana Roca',
    );
    await tester.enterText(find.bySemanticsLabel('Teléfono'), '77123456');
    await tester.enterText(
      find.bySemanticsLabel('Usuario'),
      AccesoDemo.usuarioOcupado,
    );
    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'corta');
    final crear = find.byKey(const Key('registro-crear'));
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'segura123');
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(find.text('Ese usuario ya existe. Elige otro'), findsOneWidget);
    expect(find.text('Ana Roca'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Usuario'), 'ana.finca');
    await tester.pumpAndSettle();
    expect(find.text('Ese usuario ya existe. Elige otro'), findsNothing);
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
  });

  testWidgets('cerrar sesión desde Cuenta vuelve al ingreso', (tester) async {
    prepararTelefono(tester);
    await _abrir(tester, primerUso: false);
    await tester.pumpAndSettle();
    expect(find.text('Hola, Hugo'), findsOneWidget);

    await tester.tap(find.text('Cuenta').last);
    await tester.pumpAndSettle();
    final cerrar = find.byKey(const Key('cuenta-cerrar-sesion'));
    await tester.scrollUntilVisible(cerrar, 300);
    await tester.tap(cerrar);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('si no se puede leer la sesión guardada hay salida', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: dependenciasDePrueba(acceso: AccesoQueFalla())),
    );
    await tester.pumpAndSettle();
    expect(find.text('No pudimos abrir tu sesión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
  });

  testWidgets('en iPad horizontal el ingreso suma el panel de marca', (
    tester,
  ) async {
    prepararIpad(tester);
    await _abrir(tester);
    await _saltarPresentacion(tester);
    expect(find.text('Fumigación con drones, a pedido'), findsOneWidget);
    expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
  });

  testWidgets('los controles del acceso miden al menos 48 px', (tester) async {
    prepararTelefono(tester);
    await _abrir(tester);
    await tester.pumpAndSettle();
    for (final clave in ['onboarding-saltar', 'onboarding-continuar']) {
      expect(
        tester.getSize(find.byKey(Key(clave))).height,
        greaterThanOrEqualTo(48),
        reason: clave,
      );
    }
    await tester.tap(find.byKey(const Key('onboarding-saltar')));
    await tester.pumpAndSettle();
    for (final clave in ['login-ingresar', 'login-crear-cuenta']) {
      expect(
        tester.getSize(find.byKey(Key(clave))).height,
        greaterThanOrEqualTo(48),
        reason: clave,
      );
    }
    expect(
      tester.getSize(find.bySemanticsLabel('Usuario')).height,
      greaterThanOrEqualTo(48),
    );
  });
}
