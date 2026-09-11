// Etapa 4 de HU-05: widget test de `OrdenDetallePantalla` — botón "Abrir
// trabajo" visible solo en flavor piloto, navegación a sesión de vuelo,
// manejo de errores.

import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/features/ordenes/presentation/orden_detalle_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

// Al abrir trabajo con éxito, `OrdenDetallePantalla` navega a
// `SesionVueloPantalla`, que sí invoca `crearSesionCubit` — a diferencia de
// lo que supone el resto de los tests de este archivo (que no llegan a
// completar la apertura), el camino feliz necesita una factory real, aunque
// sus dependencias nunca se ejerciten más allá de la construcción.
SesionCubit _crearSesionCubitDeSobra(String trabajoUuidCliente) => SesionCubit(
  sesionRepositorio: _SesionRepositoryFalso(),
  personaOperativaStore: _PersonaOperativaStoreFalso(),
  trabajoUuidCliente: trabajoUuidCliente,
);

// El botón es el último elemento del ListView, fuera del viewport de 600px
// del test por defecto: `find.byKey` ignora widgets "offstage" por default,
// así que este finder desactiva ese filtro (y `ensureVisible` lo scrollea a
// la vista antes de tocarlo, como haría un piloto real).
Finder _botonAbrirTrabajo() =>
    find.byKey(const Key('boton_abrir_trabajo'), skipOffstage: false);

OrdenVigente _orden({
  int id = 1,
  String? loteCodigo = 'L-01',
  Decimal? loteHectareas,
}) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: 1,
  nroAplicacion: 2,
  litrosHa: Decimal.parse('12.5'),
  humedadMinPct: Decimal.parse('60'),
  vientoMaxKmh: Decimal.parse('15'),
  temperaturaMaxC: Decimal.parse('32'),
  humedadMaxPct: Decimal.parse('90'),
  velocidadMaxKmh: Decimal.parse('25'),
  alturaVueloM: Decimal.parse('3'),
  velocidadVueloKmh: Decimal.parse('18'),
  anchoPasadaM: Decimal.parse('7'),
  observaciones: 'Test',
  emitidaPorContactoId: 2,
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
  loteCodigo: loteCodigo,
  loteHectareas: loteHectareas,
);

Trabajo _trabajo({
  String uuidCliente = 'uuid-trabajo-1',
  int ordenId = 1,
  int loteId = 1,
  int nroAplicacion = 2,
  Decimal? hectareasDeclaradas,
}) => Trabajo(
  uuidCliente: uuidCliente,
  ordenId: ordenId,
  loteId: loteId,
  nroAplicacion: nroAplicacion,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('0'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
);

void main() {
  late _TrabajoRepositoryFalso trabajoRepositorio;

  setUp(() {
    trabajoRepositorio = _TrabajoRepositoryFalso();
  });

  testWidgets('flavor piloto: botón "Abrir trabajo" visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          // Fresco por invocación, igual que en producción
          // (`main_piloto.dart`): `BlocProvider(create: ...)` toma
          // posesión del cubit y lo cierra solo al desmontar — un
          // `addTearDown(cubit.close)` sobre la misma instancia duplica
          // el cierre y cuelga la finalización del test.
          crearTrabajoCubit: () => TrabajoCubit(trabajoRepositorio),
          crearSesionCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());

    expect(_botonAbrirTrabajo(), findsOneWidget);
  });

  testWidgets('flavor auxiliar: botón "Abrir trabajo" NO visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.auxiliar,
          crearTrabajoCubit: () => TrabajoCubit(trabajoRepositorio),
          crearSesionCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_botonAbrirTrabajo(), findsNothing);
  });

  testWidgets('tap al botón: muestra carga', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _trabajo();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () => TrabajoCubit(trabajoRepositorio),
          // Camino feliz: la apertura exitosa navega a SesionVueloPantalla,
          // que sí construye un SesionCubit.
          crearSesionCubit: _crearSesionCubitDeSobra,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    await tester.tap(_botonAbrirTrabajo());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // En éxito, navega; el spinner desaparece
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error al abrir trabajo: muestra SnackBar', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenThrow(Exception('Error simulado'));

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () => TrabajoCubit(trabajoRepositorio),
          crearSesionCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    await tester.tap(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Error al abrir trabajo'), findsOneWidget);
  });

  testWidgets('botón deshabilitado mientras carga', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _trabajo();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () => TrabajoCubit(trabajoRepositorio),
          // Camino feliz (tras el segundo transcurrido): navega a
          // SesionVueloPantalla, que sí construye un SesionCubit.
          crearSesionCubit: _crearSesionCubitDeSobra,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boton = _botonAbrirTrabajo();
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    expect((tester.widget(boton) as FilledButton).onPressed, isNotNull);

    await tester.tap(boton);
    await tester.pump();

    // Mientras carga, el botón está deshabilitado (onPressed == null)
    expect((tester.widget(boton) as FilledButton).onPressed, isNull);

    // Drena el Future retrasado de 1s pendiente: dejarlo sin resolver deja
    // un Timer vivo que `flutter_test` rechaza al finalizar el test.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
