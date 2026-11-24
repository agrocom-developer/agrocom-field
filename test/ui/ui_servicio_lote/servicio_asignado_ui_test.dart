// UI de los servicios asignados (tarea 46) en los flavors piloto y
// auxiliar: la lista, el detalle y el recorrido completo de una sesión de
// vuelo sobre los repositorios en memoria del perfil demo.

import 'package:agrocom_field/auxiliar/servicio_asignado/domain/servicio_asignado_auxiliar_repositorio.dart';
import 'package:agrocom_field/auxiliar/servicio_asignado/presentation/servicio_auxiliar_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/piloto/demo/sesion_vuelo_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';
import 'package:agrocom_field/piloto/servicio_asignado/presentation/servicio_detalle_pantalla.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

class _ServicioAuxiliarFijo implements ServicioAsignadoAuxiliarRepositorio {
  _ServicioAuxiliarFijo(this._servicio);

  final Servicio? _servicio;

  @override
  Stream<Servicio?> observar() => Stream.value(_servicio);
}

AlmacenDemoProveedor _almacen() =>
    AlmacenDemoProveedor(datos: DatosDemo(reloj: () => ahoraFijo));

Future<AlmacenDemoProveedor> _abrirServicios(WidgetTester tester) async {
  final almacen = _almacen();
  await tester.pumpWidget(
    AppPilotoDemo(dependencias: DependenciasPiloto.demo(almacen: almacen)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Servicio').last);
  await tester.pumpAndSettle();
  return almacen;
}

Future<void> _montarAuxiliar(WidgetTester tester, Servicio? servicio) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(),
      home: RepositoryProvider<ServicioAsignadoAuxiliarRepositorio>.value(
        value: _ServicioAuxiliarFijo(servicio),
        child: const Scaffold(
          body: SafeArea(child: ServicioAuxiliarPantalla()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  group('pantallas', () {
    variantesDePantalla('piloto_mis_servicios', _abrirServicios);

    variantesDePantalla('piloto_servicio_detalle', (tester) async {
      await _abrirServicios(tester);
      await tester.ensureVisible(find.byKey(const Key('boton_ver_detalle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_ver_detalle')));
      await tester.pumpAndSettle();
      expect(find.byType(ServicioDetallePantalla), findsOneWidget);
    });

    variantesDePantalla('auxiliar_servicio', (tester) async {
      await _montarAuxiliar(
        tester,
        DatosDemo(reloj: () => ahoraFijo).servicios.first,
      );
    });

    variantesDePantalla('auxiliar_sin_servicio', (tester) async {
      await _montarAuxiliar(tester, null);
    });
  });

  group('piloto', () {
    testWidgets('el servicio vigente muestra su avance y una acción '
        'principal de al menos 56 px', (tester) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _abrirServicios(tester);

      expect(find.text('Mis servicios'), findsOneWidget);
      expect(find.text('HECTÁREAS CUBIERTAS'), findsOneWidget);
      expect(find.byKey(const Key('indicador_sync')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('boton_abrir_sesion_vuelo')),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('boton_abrir_sesion_vuelo')))
            .height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('el detalle ancla la acción principal abajo, visible sin '
        'scroll', (tester) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _abrirServicios(tester);
      await tester.ensureVisible(find.byKey(const Key('boton_ver_detalle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_ver_detalle')));
      await tester.pumpAndSettle();

      final boton = tester.getRect(
        find.byKey(const Key('detalle_abrir_sesion_vuelo')),
      );
      expect(boton.height, greaterThanOrEqualTo(56));
      expect(boton.bottom, lessThanOrEqualTo(640));
      expect(find.byKey(const Key('detalle_hectareas')), findsOneWidget);
    });

    testWidgets('recorrido completo: abre la sesión con sus condiciones, la '
        'cierra con hectáreas y el avance del servicio se actualiza', (
      tester,
    ) async {
      prepararPantalla(tester, const Size(412, 915), 1);
      final almacen = await _abrirServicios(tester);
      final servicio = almacen.asignados.first;
      final antes = servicio.hectareasCubiertas;

      await tester.ensureVisible(
        find.byKey(const Key('boton_abrir_sesion_vuelo')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_abrir_sesion_vuelo')));
      await tester.pumpAndSettle();
      expect(find.byType(SesionVueloPantalla), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('apertura_viento')), '8');
      await tester.enterText(
        find.byKey(const Key('apertura_temperatura')),
        '24',
      );
      await tester.enterText(find.byKey(const Key('apertura_humedad')), '55');
      await tester.tap(find.byKey(const Key('boton_confirmar_apertura')));
      await tester.pumpAndSettle();
      expect(find.text('Sesión activa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('cierre_hectareas')), '2.5');
      await tester.tap(find.byKey(const Key('cierre_motivo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clima').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
      await tester.pumpAndSettle();
      expect(find.text('Sesión cerrada'), findsOneWidget);
      // Fue una pausa por clima: se puede abrir la sesión siguiente.
      expect(find.byKey(const Key('boton_abrir_otra_sesion')), findsOneWidget);

      expect(
        almacen.asignados.first.hectareasCubiertas,
        antes + Decimal.parse('2.5'),
      );
    });
  });

  group('repositorio de sesiones del perfil demo', () {
    test(
      'una sesión abierta bloquea abrir otra y numera en secuencia',
      () async {
        final almacen = _almacen();
        final servicio = almacen.asignados.first;
        final repo = SesionRepositoryDemo(almacen);

        Future<Sesion> abrir() => repo.abrirSesion(
          trabajoUuidCliente: servicio.id,
          pilotoId: 1,
          inicio: ahoraFijo,
          vientoKmh: Decimal.parse('8'),
          temperaturaC: Decimal.parse('24'),
          humedadPct: Decimal.parse('55'),
        );

        final primera = await abrir();
        expect(primera.secuencia, 1);
        expect(
          (await repo.restriccionAperturaDeTrabajo(servicio.id)).bloqueada,
          isTrue,
        );
        expect(await repo.sesionAbiertaDeTrabajo(servicio.id), primera);

        await repo.cerrarSesion(
          sesionUuidCliente: primera.uuidCliente,
          fin: ahoraFijo,
          motivoCierre: 'clima',
          hectareasDeclaradas: Decimal.parse('1'),
        );
        expect(
          (await repo.restriccionAperturaDeTrabajo(servicio.id)).bloqueada,
          isFalse,
        );
        final segunda = await abrir();
        expect(segunda.secuencia, 2);
        expect(segunda.uuidCliente, isNot(primera.uuidCliente));
      },
    );

    test('fuera de rango sin observación del agrónomo no abre', () async {
      final almacen = _almacen();
      final repo = SesionRepositoryDemo(almacen);

      await expectLater(
        repo.abrirSesion(
          trabajoUuidCliente: almacen.asignados.first.id,
          pilotoId: 1,
          inicio: ahoraFijo,
          vientoKmh: Decimal.parse('40'),
          temperaturaC: Decimal.parse('24'),
          humedadPct: Decimal.parse('55'),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        await repo.sesionAbiertaDeTrabajo(almacen.asignados.first.id),
        isNull,
      );
    });

    test('el avance nunca supera las hectáreas declaradas y el cierre del '
        'trabajo completa el servicio', () {
      final almacen = _almacen();
      final servicio = almacen.asignados.first;

      almacen.registrarAvance(servicio.id, Decimal.parse('100000'));
      expect(
        almacen.asignados.first.hectareasCubiertas,
        servicio.hectareasDeclaradas,
      );

      almacen.completarServicio(servicio.id);
      expect(almacen.asignados.first.estado, EstadoServicio.completado);
    });
  });
}
