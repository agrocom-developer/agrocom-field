// Etapa 2 de HU-04: widget test de `OrdenesVista` — cubit real conectado a
// un `OrdenesRepository` mockeado, para probar lista/detalle/estado vacío
// sin pasar por `OrdenesPantalla`/GetIt (mismo patrón que
// `test/features/auth/login_vista_test.dart`).

import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_cubit.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_vista.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _OrdenesRepositoryFalso extends Mock implements OrdenesRepository {}

// Nota sobre los decimales: `Decimal.toString()` recorta ceros finales
// (`Decimal.parse('12.50').toString()` == '12.5'), así que los valores acá
// se eligen sin ceros finales para que el texto esperado coincida con el
// valor de entrada sin sorpresas.
OrdenVigente _orden({
  int id = 1,
  String? loteCodigo = 'L-01',
  Decimal? loteHectareas,
  String? observaciones,
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
  observaciones: observaciones,
  emitidaPorContactoId: 2,
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
  loteCodigo: loteCodigo,
  loteHectareas: loteHectareas,
);

void main() {
  late _OrdenesRepositoryFalso repositorio;

  setUp(() {
    repositorio = _OrdenesRepositoryFalso();
  });

  Future<void> bombear(WidgetTester tester, OrdenesCubit cubit) =>
      tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OrdenesCubit>.value(
            value: cubit,
            child: const OrdenesVista(),
          ),
        ),
      );

  testWidgets('lista las ordenes vigentes que llegan por el stream', (
    tester,
  ) async {
    when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => Stream.value([_orden(id: 1), _orden(id: 2)]));
    final cubit = OrdenesCubit(repositorio);
    addTearDown(cubit.close);

    await bombear(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ordenes_lista')), findsOneWidget);
    expect(find.byKey(const Key('orden_1')), findsOneWidget);
    expect(find.byKey(const Key('orden_2')), findsOneWidget);
  });

  testWidgets('estado vacio: sin ordenes vigentes muestra el mensaje', (
    tester,
  ) async {
    when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => Stream.value(const <OrdenVigente>[]));
    final cubit = OrdenesCubit(repositorio);
    addTearDown(cubit.close);

    await bombear(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ordenes_vacia')), findsOneWidget);
    expect(find.byKey(const Key('ordenes_lista')), findsNothing);
  });

  testWidgets('tocar una orden navega al detalle con todos los campos', (
    tester,
  ) async {
    // El detalle tiene más contenido que el viewport por defecto (800x600):
    // sin agrandarlo, `ListView` no llega a construir la sección de
    // observaciones (al final) y el finder no la encuentra.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => repositorio.ordenesVigentes()).thenAnswer(
      (_) => Stream.value([
        _orden(
          id: 1,
          loteHectareas: Decimal.parse('120.5'),
          observaciones: 'Aplicar antes del mediodía',
        ),
      ]),
    );
    final cubit = OrdenesCubit(repositorio);
    addTearDown(cubit.close);

    await bombear(tester, cubit);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('orden_1')));
    await tester.pumpAndSettle();

    expect(find.text('Orden N.º 1'), findsOneWidget);
    expect(find.text('Código: L-01'), findsOneWidget);
    expect(find.text('Hectáreas: 120.5'), findsOneWidget);
    expect(find.text('Litros por hectárea: 12.5'), findsOneWidget);
    expect(find.text('Humedad mínima (%): 60'), findsOneWidget);
    expect(find.text('Altura de vuelo (m): 3'), findsOneWidget);
    expect(find.text('Aplicar antes del mediodía'), findsOneWidget);
  });

  testWidgets(
    'detalle de una orden sin lote sincronizado muestra "sin datos"',
    (tester) async {
      when(() => repositorio.ordenesVigentes()).thenAnswer(
        (_) => Stream.value([
          _orden(id: 1, loteCodigo: null, loteHectareas: null),
        ]),
      );
      final cubit = OrdenesCubit(repositorio);
      addTearDown(cubit.close);

      await bombear(tester, cubit);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('orden_1')));
      await tester.pumpAndSettle();

      expect(find.text('Código: sin datos'), findsOneWidget);
      expect(find.text('Hectáreas: sin datos'), findsOneWidget);
    },
  );
}
