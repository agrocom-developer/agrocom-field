// Etapa 2 de HU-04: `OrdenesCubit` contra un `OrdenesRepository` mockeado
// (mismo patrón que `test/features/auth/login_cubit_test.dart`) — verifica
// que cada emisión del `Stream` se traduzca al `OrdenesEstado` correcto.

import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_cubit.dart';
import 'package:agrocom_field/features/ordenes/presentation/ordenes_estado.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _OrdenesRepositoryFalso extends Mock implements OrdenesRepository {}

OrdenVigente _orden({int id = 1}) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: 1,
  nroAplicacion: 1,
  litrosHa: Decimal.parse('10.00'),
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
);

void main() {
  late _OrdenesRepositoryFalso repositorio;

  setUp(() {
    repositorio = _OrdenesRepositoryFalso();
  });

  blocTest<OrdenesCubit, OrdenesEstado>(
    'estado inicial es OrdenesCargando',
    setUp: () => when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => const Stream.empty()),
    build: () => OrdenesCubit(repositorio),
    verify: (cubit) => expect(cubit.state, const OrdenesCargando()),
  );

  blocTest<OrdenesCubit, OrdenesEstado>(
    'stream vacio emite OrdenesVacia',
    setUp: () => when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => Stream.value(const <OrdenVigente>[])),
    build: () => OrdenesCubit(repositorio),
    expect: () => [const OrdenesVacia()],
  );

  blocTest<OrdenesCubit, OrdenesEstado>(
    'stream con ordenes emite OrdenesLista',
    setUp: () => when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => Stream.value([_orden(id: 1)])),
    build: () => OrdenesCubit(repositorio),
    expect: () => [
      OrdenesLista([_orden(id: 1)]),
    ],
  );

  blocTest<OrdenesCubit, OrdenesEstado>(
    'traduce cada emision sucesiva del stream, en orden',
    setUp: () => when(() => repositorio.ordenesVigentes()).thenAnswer(
      (_) => Stream.fromIterable([
        [_orden(id: 1)],
        const <OrdenVigente>[],
        [_orden(id: 2), _orden(id: 3)],
      ]),
    ),
    build: () => OrdenesCubit(repositorio),
    expect: () => [
      OrdenesLista([_orden(id: 1)]),
      const OrdenesVacia(),
      OrdenesLista([_orden(id: 2), _orden(id: 3)]),
    ],
  );
}
