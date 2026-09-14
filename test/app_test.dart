// Etapa 2 de HU-03 + etapa 2 de HU-04 + etapa 4 de HU-05: arranque de la app
// — sin token guardado muestra login, con token guardado salta directo a la
// lista de órdenes vigentes (HU-04), leída de una `AppDatabase` en memoria
// (mismo patrón que `test/nucleo/catalogo/catalogo_repository_test.dart`).
// Etapa 4 agrega factories de trabajo/sesión pero no las invoca en estos tests.
// Etapa 2 de HU-20 agrega el último grupo: `VersionBloqueoOverlay` tapando
// login cuando `estadoVersion` emite `VersionBloqueada`.

import 'dart:async';

import 'package:agrocom_field/app.dart';
import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_cubit.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/linterna/linterna_controlador.dart';
import 'package:agrocom_field/nucleo/version/estado_version.dart';
import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TokenStoreFalso extends Mock implements TokenStore {}

class _LoginServiceFalso extends Mock implements LoginService {}

class _LinternaControladorFalso extends Mock implements LinternaControlador {}

// `OrdenesCubit` se suscribe al `Stream` del repositorio apenas se
// construye y no lo suelta hasta `close()` — a diferencia de `LoginCubit`,
// que no tiene nada pendiente entre acciones del usuario. `BlocProvider`
// cierra el cubit al desmontar el árbol, pero `close()` es async y esa
// llamada no se espera: sin capturar el cubit y cerrarlo a mano al final
// del test, la suscripción al `NativeDatabase` real queda pendiente.
//
// Cerrarlo a mano no alcanza solo: `drift` cancela esa suscripción con un
// `Timer` real internamente (para no re-ejecutar la query de inmediato si
// llega otro listener enseguida — ver el comentario en
// `StreamQueryStore.markAsClosed`, package `drift`). `testWidgets` corre
// dentro de una zona que "congela" los timers reales — solo avanzan cuando
// algo los empuja con `tester.pump(...)`, y `pumpAndSettle()` ya terminó
// para cuando cerramos el cubit. Sin `tester.runAsync(...)` ese timer
// nunca dispara y el cierre queda colgado para siempre.
OrdenesCubit Function() _crearOrdenesCubit(
  AppDatabase db,
  void Function(OrdenesCubit) alCrear,
) => () {
  final cubit = OrdenesCubit(OrdenesRepository(db));
  alCrear(cubit);
  return cubit;
};

void main() {
  late _TokenStoreFalso tokenStore;
  late _LinternaControladorFalso linterna;

  setUp(() {
    tokenStore = _TokenStoreFalso();
    linterna = _LinternaControladorFalso();
    when(() => linterna.disponible()).thenAnswer((_) async => true);
    when(() => linterna.encender()).thenAnswer((_) async {});
    when(() => linterna.apagar()).thenAnswer((_) async {});
  });

  testWidgets('sin token guardado, arranca en la pantalla de login', (
    tester,
  ) async {
    when(() => tokenStore.leerToken()).thenAnswer((_) async => null);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      AgrocomApp(
        flavor: Flavor.piloto,
        tokenStore: tokenStore,
        linternaControlador: linterna,
        estadoVersion: const Stream<EstadoVersion>.empty(),
        crearLoginCubit: () => LoginCubit(_LoginServiceFalso(), Flavor.piloto),
        // Nunca se invoca: la rama de login no llega a montar
        // `OrdenesPantalla`, así que no hay cubit que cerrar acá.
        crearOrdenesCubit: _crearOrdenesCubit(db, (_) {}),
        crearTrabajoCubit: () => throw UnimplementedError('stub no invocado'),
        crearSesionBloc: (_) => throw UnimplementedError('stub no invocado'),
        crearIncidenciaCubit: (_) =>
            throw UnimplementedError('stub no invocado'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_usuario')), findsOneWidget);
    expect(find.byKey(const Key('ordenes_lista')), findsNothing);
  });

  testWidgets(
    'en el flavor piloto, el botón de emergencia no aparece (HU-68 es exclusivo de auxiliar)',
    (tester) async {
      when(() => tokenStore.leerToken()).thenAnswer((_) async => null);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        AgrocomApp(
          flavor: Flavor.piloto,
          tokenStore: tokenStore,
          linternaControlador: linterna,
          estadoVersion: const Stream<EstadoVersion>.empty(),
          crearLoginCubit: () =>
              LoginCubit(_LoginServiceFalso(), Flavor.piloto),
          crearOrdenesCubit: _crearOrdenesCubit(db, (_) {}),
          crearTrabajoCubit: () => throw UnimplementedError('stub no invocado'),
          crearSesionBloc: (_) => throw UnimplementedError('stub no invocado'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('stub no invocado'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_usuario')), findsOneWidget);
      expect(find.byKey(const Key('emergencia_boton')), findsNothing);
    },
  );

  testWidgets(
    'en el flavor auxiliar, el botón de emergencia aparece incluso sin token y controla la linterna',
    (tester) async {
      when(() => tokenStore.leerToken()).thenAnswer((_) async => null);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        AgrocomApp(
          flavor: Flavor.auxiliar,
          tokenStore: tokenStore,
          linternaControlador: linterna,
          estadoVersion: const Stream<EstadoVersion>.empty(),
          crearLoginCubit: () =>
              LoginCubit(_LoginServiceFalso(), Flavor.auxiliar),
          crearOrdenesCubit: _crearOrdenesCubit(db, (_) {}),
          crearTrabajoCubit: () =>
              throw UnimplementedError('stub no invocado en auxiliar'),
          crearSesionBloc: (_) =>
              throw UnimplementedError('stub no invocado en auxiliar'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('stub no invocado en auxiliar'),
        ),
      );
      await tester.pumpAndSettle();

      // Visible sobre LoginPantalla, sin token ni sesión iniciada.
      expect(find.byKey(const Key('login_usuario')), findsOneWidget);
      expect(find.byKey(const Key('emergencia_boton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('emergencia_boton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('linterna_switch')), findsOneWidget);
      expect(find.text('Apagada'), findsOneWidget);

      await tester.tap(find.byKey(const Key('linterna_switch')));
      await tester.pumpAndSettle();

      verify(() => linterna.encender()).called(1);
      expect(find.text('Encendida'), findsOneWidget);

      await tester.tap(find.byKey(const Key('linterna_switch')));
      await tester.pumpAndSettle();

      verify(() => linterna.apagar()).called(1);
      expect(find.text('Apagada'), findsOneWidget);
    },
  );

  testWidgets(
    'con token guardado, salta el login y muestra la lista de órdenes',
    (tester) async {
      when(() => tokenStore.leerToken()).thenAnswer((_) async => 'un-token');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      OrdenesCubit? ordenesCubit;
      await db
          .into(db.ordenCatalogo)
          .insert(
            OrdenCatalogoCompanion.insert(
              id: const Value(1),
              contratoId: 1,
              loteId: 1,
              nroAplicacion: 1,
              litrosHa: Decimal.parse('10.00'),
              fechaEmision: '2026-08-26',
              estado: 'vigente',
              updatedAt: DateTime.utc(2026, 8, 26, 12),
            ),
          );

      await tester.pumpWidget(
        AgrocomApp(
          flavor: Flavor.auxiliar,
          tokenStore: tokenStore,
          linternaControlador: linterna,
          estadoVersion: const Stream<EstadoVersion>.empty(),
          crearLoginCubit: () =>
              LoginCubit(_LoginServiceFalso(), Flavor.auxiliar),
          crearOrdenesCubit: _crearOrdenesCubit(
            db,
            (cubit) => ordenesCubit = cubit,
          ),
          crearTrabajoCubit: () =>
              throw UnimplementedError('stub no invocado en auxiliar'),
          crearSesionBloc: (_) =>
              throw UnimplementedError('stub no invocado en auxiliar'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('stub no invocado en auxiliar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ordenes_lista')), findsOneWidget);
      expect(find.byKey(const Key('orden_1')), findsOneWidget);
      expect(find.byKey(const Key('login_usuario')), findsNothing);
      expect(find.byKey(const Key('emergencia_boton')), findsOneWidget);

      await tester.runAsync(() => ordenesCubit!.close());
    },
  );

  testWidgets(
    'HU-20: bloqueada tapa la pantalla de login, sin sesión ni token',
    (tester) async {
      when(() => tokenStore.leerToken()).thenAnswer((_) async => null);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final controladorVersion = StreamController<EstadoVersion>();
      addTearDown(controladorVersion.close);

      await tester.pumpWidget(
        AgrocomApp(
          flavor: Flavor.piloto,
          tokenStore: tokenStore,
          linternaControlador: linterna,
          estadoVersion: controladorVersion.stream,
          crearLoginCubit: () =>
              LoginCubit(_LoginServiceFalso(), Flavor.piloto),
          crearOrdenesCubit: _crearOrdenesCubit(db, (_) {}),
          crearTrabajoCubit: () => throw UnimplementedError('stub no invocado'),
          crearSesionBloc: (_) => throw UnimplementedError('stub no invocado'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('stub no invocado'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_usuario')), findsOneWidget);
      expect(find.byKey(const Key('version_bloqueada_pantalla')), findsNothing);

      const minima = VersionApk(
        version: '2.0.0',
        versionCode: 20000,
        urlDescarga: 'https://agrocom.example/apk/2.0.0',
      );
      controladorVersion.add(const VersionBloqueada(minima));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('version_bloqueada_pantalla')),
        findsOneWidget,
      );
      expect(find.textContaining('2.0.0'), findsWidgets);
      expect(find.text(minima.urlDescarga), findsOneWidget);
    },
  );
}
