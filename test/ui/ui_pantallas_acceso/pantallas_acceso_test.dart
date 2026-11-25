// Pantallas 01 a 05 del plan 02 (portadas, elegir rol, datos personales y
// equipo): comportamiento y goldens en claro y oscuro (cliente) y en modo
// campo (piloto), a ancho de teléfono chico y grande, con la fuente real.
//
// Regenerar: flutter test --update-goldens test/ui/ui_pantallas_acceso
// Los goldens solo se comparan en macOS; en otra plataforma la prueba monta
// cada pantalla y falla ante un desborde.

import 'dart:io' show Platform;

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart'
    hide MotivoFalloAcceso;
import 'package:agrocom_field/cliente/acceso/presentation/onboarding_cubit.dart';
import 'package:agrocom_field/cliente/acceso/presentation/onboarding_pantalla.dart';
import 'package:agrocom_field/cliente/acceso/presentation/registro_cliente_pantalla.dart';
import 'package:agrocom_field/nucleo/camara/selector_imagen.dart';
import 'package:agrocom_field/nucleo/marketplace/acceso/presentation/elegir_rol_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/domain/acceso_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_proveedor_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/imagenes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../cliente/dobles_cliente.dart';

const _chico = Size(360, 640);
const _grande = Size(412, 915);

final bool _conGoldens = Platform.isMacOS;

const _fotos = [
  ImagenesCampo.dronAgrasT50,
  ImagenesCampo.dronPulverizando,
  ImagenesCampo.dronPulverizandoVertical,
  ImagenesCampo.equipoDron,
];

class _AccesoFalso implements AccesoProveedorRepositorio {
  @override
  Future<SesionProveedor?> sesionActual() async => null;

  @override
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async => throw const AccesoProveedorExcepcion(
    MotivoFalloAcceso.credencialesInvalidas,
  );

  @override
  Future<void> registrar(DatosPersona datos) async {}

  @override
  Future<void> cerrarSesion() async {}
}

class _DronesFalso implements RegistroDronesRepositorio {
  @override
  Future<int> registrarDron(DatosDron datos) async => 1;

  @override
  Future<void> subirFoto(int dronId, FotoDronLista foto) async {}
}

class _Imagenes implements SelectorImagen {
  @override
  Future<Uint8List?> tomarFoto() async => null;

  @override
  Future<Uint8List?> elegirDeGaleria() async => null;
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  ModoVisualCampo modo = ModoVisualCampo.claro,
  Size tamano = _grande,
  double escala = 1,
  bool reducir = true,
}) async {
  tester.view.physicalSize = tamano * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(modo: modo),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
          disableAnimations: reducir,
        ),
        child: child!,
      ),
      home: pantalla,
    ),
  );
  await tester.runAsync(() async {
    final contexto = tester.element(find.byType(MaterialApp));
    for (final f in _fotos) {
      await precacheImage(AssetImage(f), contexto);
    }
  });
  await tester.pump(const Duration(milliseconds: 50));
}

Widget _portadas({VoidCallback? alTerminar, VoidCallback? alComenzar}) =>
    RepositoryProvider<AccesoRepositorio>.value(
      value: AccesoDemo(almacenFijo(), latencia: Duration.zero),
      child: OnboardingPantalla(
        alTerminar: alTerminar ?? () {},
        alComenzar: alComenzar,
      ),
    );

Future<void> _golden(WidgetTester tester, String nombre) async {
  if (!_conGoldens) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$nombre.png'),
  );
}

String _tam(Size t) => '${t.width.toInt()}x${t.height.toInt()}';

Widget _registro() => BlocProvider(
  create: (_) => RegistroCubit(
    acceso: _AccesoFalso(),
    drones: _DronesFalso(),
    selector: _Imagenes(),
  ),
  child: RegistroProveedorPantalla(alTerminar: () {}),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Future<void> fuente(String familia, String ruta) async {
      final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
      await cargador.load();
    }

    await fuente('Manrope', 'assets/fonts/Manrope.ttf');
    await fuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await fuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  group('01 portadas · comportamiento', () {
    testWidgets('avanza sola cada 3,5 s y da la vuelta', (tester) async {
      await _montar(tester, _portadas(), reducir: false);
      final cubit = tester
          .element(find.byType(PageView))
          .read<OnboardingCubit>();
      expect(cubit.state.paso, 0);
      await tester.pump(const Duration(milliseconds: 3400));
      expect(cubit.state.paso, 0);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.paso, 1);
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.paso, 0, reason: 'después de la tercera vuelve');
    });

    testWidgets('se pausa mientras se toca y reinicia la cuenta al soltar', (
      tester,
    ) async {
      await _montar(tester, _portadas(), reducir: false);
      final cubit = tester
          .element(find.byType(PageView))
          .read<OnboardingCubit>();
      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(const Duration(seconds: 8));
      expect(cubit.state.paso, 0, reason: 'pausado con el dedo puesto');
      await gesto.up();
      await tester.pump(const Duration(milliseconds: 3000));
      expect(cubit.state.paso, 0, reason: 'la cuenta empezó de nuevo');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.paso, 1);
    });

    testWidgets('tocar un punto salta a esa portada', (tester) async {
      await _montar(tester, _portadas(), reducir: false);
      final cubit = tester
          .element(find.byType(PageView))
          .read<OnboardingCubit>();
      await tester.tap(find.byKey(const Key('onboarding-punto-2')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.paso, 2);
      expect(find.text('Pagas lo que se fumigó'), findsOneWidget);
    });

    testWidgets('con reducir movimiento no avanza sola', (tester) async {
      await _montar(tester, _portadas());
      final cubit = tester
          .element(find.byType(PageView))
          .read<OnboardingCubit>();
      await tester.pump(const Duration(seconds: 20));
      expect(cubit.state.paso, 0);
      await tester.tap(find.byKey(const Key('onboarding-punto-1')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(cubit.state.paso, 1);
    });

    testWidgets('Comenzar abre el registro', (tester) async {
      var comenzar = 0;
      var terminar = 0;
      await _montar(
        tester,
        _portadas(alComenzar: () => comenzar++, alTerminar: () => terminar++),
      );
      await tester.tap(find.byKey(const Key('onboarding-continuar')));
      await tester.pump(const Duration(milliseconds: 50));
      expect((comenzar, terminar), (1, 0));
    });

    testWidgets('Ya tengo cuenta abre el ingreso', (tester) async {
      var comenzar = 0;
      var terminar = 0;
      await _montar(
        tester,
        _portadas(alComenzar: () => comenzar++, alTerminar: () => terminar++),
      );
      await tester.tap(find.byKey(const Key('onboarding-tengo-cuenta')));
      await tester.pump(const Duration(milliseconds: 50));
      expect((comenzar, terminar), (0, 1));
    });

    testWidgets('Saltar termina la presentación', (tester) async {
      var terminar = 0;
      await _montar(tester, _portadas(alTerminar: () => terminar++));
      await tester.tap(find.byKey(const Key('onboarding-saltar')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(terminar, 1);
    });

    testWidgets('se lee completo con el texto al 200 %', (tester) async {
      await _montar(tester, _portadas(), tamano: _chico, escala: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Comenzar'), findsOneWidget);
    });
  });

  group('04 registro del cliente · persona o empresa', () {
    Widget registro() => RepositoryProvider<AccesoRepositorio>.value(
      value: AccesoDemo(almacenFijo(), latencia: Duration.zero),
      child: RegistroClientePantalla(alEntrar: (_) {}, alVolver: () {}),
    );

    testWidgets('Empresa pide razón social y NIT; Persona no', (tester) async {
      await _montar(tester, registro());
      expect(find.byKey(const Key('registro-razon-social')), findsNothing);
      await tester.tap(find.text('Empresa'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('registro-razon-social')), findsOneWidget);
      expect(
        find.byKey(const Key('registro-documento-fiscal')),
        findsOneWidget,
      );
      await tester.tap(find.text('Persona'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('registro-razon-social')), findsNothing);
    });

    testWidgets('Empresa: golden claro y oscuro', (tester) async {
      for (final modo in [ModoVisualCampo.claro, ModoVisualCampo.oscuro]) {
        await _montar(tester, registro(), modo: modo, tamano: _chico);
        await tester.tap(find.text('Empresa'));
        await tester.pump(const Duration(milliseconds: 50));
        await _golden(tester, 'registro_cliente_empresa_${modo.name}_360x640');
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('03 elegir rol · comportamiento', () {
    testWidgets('ofrece solo Cliente y Piloto y cambia el botón', (
      tester,
    ) async {
      RolElegido? elegido;
      await _montar(
        tester,
        ElegirRolPantalla(
          alContinuar: (r) => elegido = r,
          alTenerCuenta: () {},
        ),
      );
      expect(find.text('Auxiliar'), findsNothing);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Piloto'), findsOneWidget);
      expect(find.text('Continuar como cliente'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rol-piloto')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Continuar como piloto'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rol-continuar')));
      expect(elegido, RolElegido.piloto);
    });

    testWidgets('el botón avisa que está en curso mientras carga', (
      tester,
    ) async {
      await _montar(
        tester,
        ElegirRolPantalla(
          alContinuar: (_) {},
          alTenerCuenta: () {},
          cargando: true,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('en curso')), findsOneWidget);
    });
  });

  group('goldens', () {
    for (final tamano in [_chico, _grande]) {
      final t = _tam(tamano);

      testWidgets('portadas, claro $t', (tester) async {
        await _montar(tester, _portadas(), tamano: tamano);
        await _golden(tester, 'portada_1_claro_$t');
        await tester.tap(find.byKey(const Key('onboarding-punto-1')));
        await tester.pump(const Duration(milliseconds: 50));
        await _golden(tester, 'portada_2_claro_$t');
        await tester.tap(find.byKey(const Key('onboarding-punto-2')));
        await tester.pump(const Duration(milliseconds: 50));
        await _golden(tester, 'portada_3_claro_$t');
        expect(tester.takeException(), isNull);
      });

      testWidgets('portadas, oscuro $t', (tester) async {
        await _montar(
          tester,
          _portadas(),
          modo: ModoVisualCampo.oscuro,
          tamano: tamano,
        );
        await _golden(tester, 'portada_1_oscuro_$t');
        await tester.tap(find.byKey(const Key('onboarding-punto-1')));
        await tester.pump(const Duration(milliseconds: 50));
        await _golden(tester, 'portada_2_oscuro_$t');
        expect(tester.takeException(), isNull);
      });

      for (final (modo, nombre) in [
        (ModoVisualCampo.claro, 'claro'),
        (ModoVisualCampo.oscuro, 'oscuro'),
        (ModoVisualCampo.campo, 'campo'),
      ]) {
        testWidgets('elegir rol, $nombre $t', (tester) async {
          await _montar(
            tester,
            ElegirRolPantalla(alContinuar: (_) {}, alTenerCuenta: () {}),
            modo: modo,
            tamano: tamano,
          );
          await _golden(tester, 'rol_${nombre}_$t');
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('registro del piloto: datos y equipo, campo $t', (
        tester,
      ) async {
        await _montar(
          tester,
          _registro(),
          modo: ModoVisualCampo.campo,
          tamano: tamano,
        );
        expect(find.text('PASO 1 DE 4'), findsOneWidget);
        await _golden(tester, 'registro_datos_campo_$t');
        expect(tester.takeException(), isNull);
      });

      testWidgets('registro del piloto: datos, claro $t', (tester) async {
        await _montar(tester, _registro(), tamano: tamano);
        await _golden(tester, 'registro_datos_claro_$t');
        expect(tester.takeException(), isNull);
      });
    }

    for (final (modo, nombre) in [
      (ModoVisualCampo.campo, 'campo'),
      (ModoVisualCampo.claro, 'claro'),
    ]) {
      testWidgets('registro del piloto: equipo (paso 3), $nombre', (
        tester,
      ) async {
        await _montar(tester, _registro(), modo: modo);
        Future<void> escribir(String etiqueta, String valor) async {
          await tester.ensureVisible(find.bySemanticsLabel(etiqueta));
          await tester.enterText(find.bySemanticsLabel(etiqueta), valor);
        }

        Future<void> fecha(String etiqueta) async {
          final campo = find.bySemanticsLabel(RegExp('^$etiqueta')).first;
          await tester.ensureVisible(campo);
          await tester.tap(campo);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('OK'));
          await tester.pump(const Duration(milliseconds: 300));
        }

        Future<void> continuar() async {
          final boton = find.text('Continuar');
          await tester.ensureVisible(boton);
          await tester.tap(boton);
          await tester.pump(const Duration(milliseconds: 100));
        }

        await escribir('Nombres', 'Rodrigo');
        await escribir('Apellidos', 'Suárez Roca');
        await escribir('Carnet de identidad', '7654321');
        await fecha('Fecha de nacimiento');
        await escribir('Teléfono', '71234567');
        await escribir('Usuario', 'rodrigo.suarez');
        await escribir('Contraseña', 'segura1234');
        await continuar();
        expect(find.text('PASO 2 DE 4'), findsOneWidget);
        await escribir('Número de licencia de piloto', 'LIC-2291');
        await fecha('Vence el');
        await escribir('Categoría de habilitación', 'AGRO-2');
        await continuar();
        expect(find.text('PASO 3 DE 4'), findsOneWidget);
        expect(find.text('Tu equipo'), findsOneWidget);
        await _golden(tester, 'registro_equipo_${nombre}_412x915');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
