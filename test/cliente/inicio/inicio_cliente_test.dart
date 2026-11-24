// Inicio del cliente: reglas del resumen, cubit y pantalla en sus estados.

import 'dart:async';

import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/inicio/data/inicio_cliente_demo.dart';
import 'package:agrocom_field/cliente/inicio/domain/inicio_cliente_repositorio.dart';
import 'package:agrocom_field/cliente/inicio/domain/reglas_inicio_cliente.dart';
import 'package:agrocom_field/cliente/inicio/presentation/inicio_cliente_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../nucleo/marketplace/ayudas_prueba.dart';
import '../dobles_cliente.dart';

ResumenInicio _resumenDemo() => ReglasInicioCliente.resumir(
  nombre: 'Hugo',
  empresa: 'Agropecuaria Los Tajibos',
  servicios: almacenFijo().servicios,
  avisos: InicioClienteDemo.avisos,
);

Future<void> _abrir(
  WidgetTester tester,
  InicioClienteRepositorio inicio,
) async {
  await tester.pumpWidget(
    AppCliente(dependencias: dependenciasDePrueba(inicio: inicio)),
  );
  // La splash termina; el inicio queda en el estado que dicte `inicio`.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('ReglasInicioCliente', () {
    test('el servicio activo principal es el que está en ejecución', () {
      final r = _resumenDemo();
      expect(r.servicioActivo?.estado, EstadoServicio.enEjecucion);
      expect(r.otrosActivos, 2);
      expect(r.porCalificar, isNotEmpty);
      expect(
        r.recientes.length,
        lessThanOrEqualTo(ReglasInicioCliente.maximoRecientes),
      );
      expect(r.recientes.every((s) => s.puntajeDelCliente != null), isTrue);
    });

    test('sin servicios no hay activo ni historial', () {
      final r = ReglasInicioCliente.resumir(nombre: 'Ana', servicios: const []);
      expect(r.servicioActivo, isNull);
      expect(r.otrosActivos, 0);
      expect(r.recientes, isEmpty);
    });

    test('sin ninguno volando toma el activo más reciente', () {
      final servicios = almacenFijo().servicios
          .where((s) => s.estado != EstadoServicio.enEjecucion)
          .toList();
      final r = ReglasInicioCliente.resumir(
        nombre: 'Ana',
        servicios: servicios,
      );
      expect(
        r.servicioActivo?.id,
        servicios.firstWhere((s) => s.estado.activo).id,
      );
    });
  });

  group('InicioClienteCubit', () {
    blocTest<InicioClienteCubit, InicioClienteEstado>(
      'carga y expone el resumen',
      build: () => InicioClienteCubit(InicioControlado.fijo(_resumenDemo())),
      act: (c) => c.cargar(),
      expect: () => [
        isA<InicioClienteCargando>(),
        isA<InicioClienteListo>().having(
          (e) => e.resumen.avisos.length,
          'avisos',
          2,
        ),
      ],
    );

    blocTest<InicioClienteCubit, InicioClienteEstado>(
      'un error de red queda como sin conexión',
      build: () => InicioClienteCubit(
        InicioControlado(() => Stream.error(const InicioSinConexion())),
      ),
      act: (c) => c.cargar(),
      skip: 1,
      expect: () => [
        isA<InicioClienteFallido>().having(
          (e) => e.sinConexion,
          'sinConexion',
          isTrue,
        ),
      ],
    );

    test('un aviso descartado no vuelve al actualizar', () async {
      final cubit = InicioClienteCubit(InicioControlado.fijo(_resumenDemo()))
        ..cargar();
      await Future<void>.delayed(Duration.zero);
      cubit.descartarAviso('clima-favorable');
      expect((cubit.state as InicioClienteListo).resumen.avisos.length, 1);
      await cubit.actualizar();
      expect((cubit.state as InicioClienteListo).resumen.avisos.length, 1);
      await cubit.close();
    });
  });

  group('InicioClientePantalla', () {
    testWidgets('mientras carga muestra el esqueleto', (tester) async {
      prepararTelefono(tester);
      await _abrir(tester, InicioControlado.pendiente());
      expect(find.byType(EsqueletoCampo), findsWidgets);
      expect(find.text('Solicitar un servicio'), findsNothing);
    });

    testWidgets('muestra solicitar, servicio activo, avisos e historial', (
      tester,
    ) async {
      prepararTelefono(tester);
      await _abrir(tester, InicioControlado.fijo(_resumenDemo()));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Hugo'), findsOneWidget);
      expect(find.text('Solicitar un servicio'), findsOneWidget);
      expect(find.text('Servicio activo'), findsOneWidget);
      expect(find.text('Seguir en vivo'), findsOneWidget);
      expect(find.text('Ver los otros 2 servicios activos'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Avisos'), 200);
      await tester.scrollUntilVisible(find.text('Historial reciente'), 200);
      expect(find.text('Ver todo'), findsOneWidget);
    });

    testWidgets('descartar un aviso lo quita de la lista', (tester) async {
      prepararTelefono(tester);
      await _abrir(tester, InicioControlado.fijo(_resumenDemo()));
      await tester.pumpAndSettle();
      final aviso = find.text('Buen clima para aplicar mañana');
      await tester.scrollUntilVisible(aviso, 200);
      await tester.tap(find.byTooltip('Descartar aviso').first);
      await tester.pumpAndSettle();
      expect(aviso, findsNothing);
      expect(find.text('Alta demanda esta semana'), findsOneWidget);
    });

    testWidgets('«Ver todo» lleva a la pestaña Servicios', (tester) async {
      prepararTelefono(tester);
      await _abrir(tester, InicioControlado.fijo(_resumenDemo()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Ver todo'), 200);
      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();
      expect(find.text('Mis servicios'), findsOneWidget);
    });

    testWidgets('sin servicios orienta hacia la primera solicitud', (
      tester,
    ) async {
      prepararTelefono(tester);
      await _abrir(
        tester,
        InicioControlado.fijo(const ResumenInicio(nombre: 'Ana')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('No tienes servicios en curso'), findsOneWidget);
      expect(find.text('Historial reciente'), findsNothing);
      await tester.tap(find.byKey(const Key('inicio-solicitar')));
      await tester.pumpAndSettle();
      expect(find.text('Paso 1 de 3 · Dónde'), findsOneWidget);
    });

    testWidgets('sin conexión explica y permite reintentar', (tester) async {
      prepararTelefono(tester);
      var intentos = 0;
      final inicio = InicioControlado(() {
        intentos++;
        return intentos == 1
            ? Stream.error(const InicioSinConexion())
            : Stream.value(_resumenDemo());
      });
      await _abrir(tester, inicio);
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inicio-reintentar')));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Hugo'), findsOneWidget);
    });

    testWidgets('volver a la pestaña Inicio no repite la carga', (
      tester,
    ) async {
      prepararTelefono(tester);
      final inicio = InicioControlado.fijo(_resumenDemo());
      await _abrir(tester, inicio);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuenta').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();
      expect(find.text('Hola, Hugo'), findsOneWidget);
      expect(inicio.suscripciones, 1);
    });

    testWidgets('en iPad el inicio se parte en dos columnas', (tester) async {
      prepararIpad(tester);
      await _abrir(tester, InicioControlado.fijo(_resumenDemo()));
      await tester.pumpAndSettle();
      final solicitar = tester.getTopLeft(
        find.byKey(const Key('inicio-solicitar')),
      );
      final avisos = tester.getTopLeft(find.text('Avisos'));
      expect(avisos.dx, greaterThan(solicitar.dx + 200));
    });
  });
}
