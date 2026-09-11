// Etapa 2 de HU-03 + etapa 2 de HU-04 + etapa 4 de HU-05: arranque de la app
// — sin token guardado muestra login, con token guardado salta directo a la
// lista de órdenes vigentes (HU-04), leída de una `AppDatabase` en memoria
// (mismo patrón que `test/nucleo/catalogo/catalogo_repository_test.dart`).
// Etapa 4 agrega factories de trabajo/sesión pero no las invoca en estos tests.

import 'package:agrocom_field/app.dart';
import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_cubit.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TokenStoreFalso extends Mock implements TokenStore {}

class _LoginServiceFalso extends Mock implements LoginService {}

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

  setUp(() {
    tokenStore = _TokenStoreFalso();
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
        crearLoginCubit: () => LoginCubit(_LoginServiceFalso(), Flavor.piloto),
        // Nunca se invoca: la rama de login no llega a montar
        // `OrdenesPantalla`, así que no hay cubit que cerrar acá.
        crearOrdenesCubit: _crearOrdenesCubit(db, (_) {}),
        crearTrabajoCubit: () => throw UnimplementedError('stub no invocado'),
        crearSesionBloc: (_) => throw UnimplementedError('stub no invocado'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_usuario')), findsOneWidget);
    expect(find.byKey(const Key('ordenes_lista')), findsNothing);
  });

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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ordenes_lista')), findsOneWidget);
      expect(find.byKey(const Key('orden_1')), findsOneWidget);
      expect(find.byKey(const Key('login_usuario')), findsNothing);

      await tester.runAsync(() => ordenesCubit!.close());
    },
  );
}
