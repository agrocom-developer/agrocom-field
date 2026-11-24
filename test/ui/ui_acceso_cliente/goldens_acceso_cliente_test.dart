// Goldens del acceso y del inicio del cliente: splash, presentación,
// ingreso, registro e inicio, en claro y oscuro, con sus estados (carga,
// vacío, error), a texto 200 % y en iPad.
//
// Se generan con el motor de Flutter sobre la app real (`AppCliente`) y
// repositorios demo de reloj fijo. Regenerar:
//   flutter test --update-goldens test/ui/ui_acceso_cliente
//
// Solo corren en macOS: el render de texto difiere en Linux (CI).

import 'dart:io' show Platform;

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/inicio/domain/inicio_cliente_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/imagenes_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../cliente/dobles_cliente.dart';

const _telefono = Size(390, 844);
const _telefonoChico = Size(360, 640);
const _ipadHorizontal = Size(1194, 834);
const _ipadVertical = Size(834, 1194);

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
  await cargador.load();
}

const _imagenes = [
  ImagenesCampo.logo,
  ImagenesCampo.dronPulverizandoVertical,
  ImagenesCampo.equipoDron,
  ImagenesCampo.dronAgrasT50,
];

/// Abre la app con [dependencias] en el tamaño, tema y escala pedidos, con
/// movimiento reducido (las animaciones quedan en su estado final).
Future<void> _abrir(
  WidgetTester tester,
  DependenciasCliente dependencias, {
  Size tamano = _telefono,
  bool oscuro = false,
  double escala = 1,
}) async {
  ConfiguracionMapa.teselas = false;
  final proporcion = tamano.width >= 600 ? 1.0 : 2.0;
  tester.view.physicalSize = tamano * proporcion;
  tester.view.devicePixelRatio = proporcion;
  final plataforma = tester.platformDispatcher;
  plataforma.platformBrightnessTestValue = oscuro
      ? Brightness.dark
      : Brightness.light;
  plataforma.textScaleFactorTestValue = escala;
  plataforma.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
    disableAnimations: true,
  );
  addTearDown(() {
    tester.view.reset();
    plataforma.clearAllTestValues();
    ConfiguracionMapa.teselas = true;
  });

  await tester.pumpWidget(AppCliente(dependencias: dependencias));
  // Las fotos y el logo se decodifican fuera del reloj falso del test.
  await tester.runAsync(() async {
    final contexto = tester.element(find.byType(MaterialApp));
    for (final imagen in _imagenes) {
      await precacheImage(AssetImage(imagen), contexto);
    }
  });
  await _asentar(tester);
}

/// Avanza lo suficiente para que terminen splash y fundidos. No se usa
/// `pumpAndSettle`: con un repositorio pendiente no hay nada que asentar.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _comparar(WidgetTester tester, String nombre) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$nombre.png'),
);

Future<void> _tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await _asentar(tester);
}

Future<void> _irAlRegistro(WidgetTester tester) =>
    _tocar(tester, find.byKey(const Key('login-crear-cuenta')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _cargarFuente('Manrope', 'assets/fonts/Manrope.ttf');
    await _cargarFuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await _cargarFuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  final saltar = !Platform.isMacOS;

  DependenciasCliente primerUso() => dependenciasDePrueba(primerUso: true);
  DependenciasCliente sinSesion() => dependenciasDePrueba(
    acceso: AccesoDemo(
      almacenFijo(),
      latencia: Duration.zero,
      onboardingVisto: true,
    ),
  );

  for (final oscuro in [false, true]) {
    final modo = oscuro ? 'oscuro' : 'claro';

    group('teléfono, modo $modo', () {
      testWidgets('splash', skip: saltar, (tester) async {
        await _abrir(
          tester,
          dependenciasDePrueba(acceso: AccesoPendiente()),
          oscuro: oscuro,
        );
        await _comparar(tester, 'splash_$modo');
      });

      testWidgets('presentación, los tres pasos', skip: saltar, (tester) async {
        await _abrir(tester, primerUso(), oscuro: oscuro);
        await _comparar(tester, 'onboarding_1_$modo');
        await _tocar(tester, find.byKey(const Key('onboarding-continuar')));
        // Los pasos 2 y 3 solo cambian foto y texto: con el modo claro
        // alcanza y el repositorio no carga cuatro fotos más.
        if (!oscuro) await _comparar(tester, 'onboarding_2_$modo');
        await _tocar(tester, find.byKey(const Key('onboarding-continuar')));
        if (!oscuro) await _comparar(tester, 'onboarding_3_$modo');
      });

      testWidgets('ingreso: vacío, validación y error', skip: saltar, (
        tester,
      ) async {
        await _abrir(tester, sinSesion(), oscuro: oscuro);
        await _comparar(tester, 'login_$modo');

        await _tocar(tester, find.byKey(const Key('login-ingresar')));
        await _comparar(tester, 'login_validacion_$modo');

        await tester.enterText(find.bySemanticsLabel('Correo'), 'ana@finca.bo');
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          AccesoDemo.contrasenaIncorrecta,
        );
        await _tocar(tester, find.byKey(const Key('login-ingresar')));
        await _comparar(tester, 'login_error_$modo');

        await tester.enterText(
          find.bySemanticsLabel('Correo'),
          AccesoDemo.correoSinConexion,
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          'segura123',
        );
        await _tocar(tester, find.byKey(const Key('login-ingresar')));
        await _comparar(tester, 'login_sin_conexion_$modo');
      });

      testWidgets('registro: vacío y error por campo', skip: saltar, (
        tester,
      ) async {
        await _abrir(tester, sinSesion(), oscuro: oscuro);
        await _irAlRegistro(tester);
        await _comparar(tester, 'registro_$modo');

        await tester.enterText(
          find.bySemanticsLabel('Nombre completo'),
          'Ana Roca Vaca',
        );
        await tester.enterText(find.bySemanticsLabel('Teléfono'), '771');
        await tester.enterText(
          find.bySemanticsLabel('Correo'),
          AccesoDemo.correoOcupado,
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          'segura123',
        );
        await _tocar(tester, find.byKey(const Key('registro-crear')));
        await tester.enterText(find.bySemanticsLabel('Teléfono'), '77123456');
        await _tocar(tester, find.byKey(const Key('registro-crear')));
        await _comparar(tester, 'registro_error_campo_$modo');
      });

      testWidgets('inicio: con servicios', skip: saltar, (tester) async {
        await _abrir(tester, dependenciasDePrueba(), oscuro: oscuro);
        await _comparar(tester, 'inicio_$modo');
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -620),
        );
        await _asentar(tester);
        await _comparar(tester, 'inicio_abajo_$modo');
      });

      testWidgets('inicio: cargando', skip: saltar, (tester) async {
        await _abrir(
          tester,
          dependenciasDePrueba(inicio: InicioControlado.pendiente()),
          oscuro: oscuro,
        );
        await _comparar(tester, 'inicio_cargando_$modo');
      });

      testWidgets('inicio: sin servicios', skip: saltar, (tester) async {
        await _abrir(
          tester,
          dependenciasDePrueba(
            inicio: InicioControlado.fijo(const ResumenInicio(nombre: 'Ana')),
          ),
          oscuro: oscuro,
        );
        await _comparar(tester, 'inicio_vacio_$modo');
      });

      testWidgets('inicio: sin conexión', skip: saltar, (tester) async {
        await _abrir(
          tester,
          dependenciasDePrueba(
            inicio: InicioControlado(
              () => Stream.error(const InicioSinConexion()),
            ),
          ),
          oscuro: oscuro,
        );
        await _comparar(tester, 'inicio_sin_conexion_$modo');
      });
    });
  }

  group('texto al 200 % en 360 x 640', () {
    testWidgets('presentación', skip: saltar, (tester) async {
      await _abrir(tester, primerUso(), tamano: _telefonoChico, escala: 2);
      await _comparar(tester, 'onboarding_1_texto200');
    });

    testWidgets('ingreso y registro', skip: saltar, (tester) async {
      await _abrir(tester, sinSesion(), tamano: _telefonoChico, escala: 2);
      await _comparar(tester, 'login_texto200');
      await _irAlRegistro(tester);
      await _comparar(tester, 'registro_texto200');
    });

    testWidgets('inicio', skip: saltar, (tester) async {
      await _abrir(
        tester,
        dependenciasDePrueba(),
        tamano: _telefonoChico,
        escala: 2,
      );
      await _comparar(tester, 'inicio_texto200');
    });
  });

  group('iPad', () {
    testWidgets('horizontal: presentación, ingreso e inicio', skip: saltar, (
      tester,
    ) async {
      await _abrir(tester, primerUso(), tamano: _ipadHorizontal);
      await _comparar(tester, 'ipad_h_onboarding_1');
      await _tocar(tester, find.byKey(const Key('onboarding-saltar')));
      await _comparar(tester, 'ipad_h_login');
      await tester.enterText(find.bySemanticsLabel('Correo'), 'ana@finca.bo');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'segura123');
      await _tocar(tester, find.byKey(const Key('login-ingresar')));
      await _comparar(tester, 'ipad_h_inicio');
    });

    testWidgets('horizontal oscuro: inicio', skip: saltar, (tester) async {
      await _abrir(
        tester,
        dependenciasDePrueba(),
        tamano: _ipadHorizontal,
        oscuro: true,
      );
      await _comparar(tester, 'ipad_h_inicio_oscuro');
    });

    testWidgets('vertical: presentación, registro e inicio', skip: saltar, (
      tester,
    ) async {
      await _abrir(tester, primerUso(), tamano: _ipadVertical);
      await _comparar(tester, 'ipad_v_onboarding_1');
      await _tocar(tester, find.byKey(const Key('onboarding-saltar')));
      await _irAlRegistro(tester);
      await _comparar(tester, 'ipad_v_registro');
    });

    testWidgets('vertical: inicio', skip: saltar, (tester) async {
      await _abrir(tester, dependenciasDePrueba(), tamano: _ipadVertical);
      await _comparar(tester, 'ipad_v_inicio');
    });
  });
}
