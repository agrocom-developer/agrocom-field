// HU-70: `InicioCubit` contra un `InicioRepository` mockeado — cada emisión
// del stream local se traduce al estado correcto, el vacío incluido.

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_cubit.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_estado.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _InicioRepositoryFalso extends Mock implements InicioRepository {}

final _trabajo = TrabajoAsignado(
  id: 42,
  uuidCliente: 'uuid-panel-42',
  ordenId: 1,
  loteId: 3,
  hectareasDeclaradas: Decimal.parse('300.00'),
  equipoTrabajoId: 7,
  updatedAt: DateTime.utc(2026, 9, 22),
);

void main() {
  late _InicioRepositoryFalso repositorio;

  setUp(() {
    repositorio = _InicioRepositoryFalso();
    // Tarea 27: por defecto nada en curso (no emite) — estos tests miran
    // solo el trabajo asignado.
    when(() => repositorio.enCurso()).thenAnswer((_) => const Stream.empty());
  });

  blocTest<InicioCubit, InicioEstado>(
    'estado inicial es InicioCargando',
    setUp: () => when(
      () => repositorio.trabajoAsignado(),
    ).thenAnswer((_) => const Stream.empty()),
    build: () => InicioCubit(repositorio),
    verify: (cubit) => expect(cubit.state, const InicioCargando()),
  );

  blocTest<InicioCubit, InicioEstado>(
    'null → InicioSinTrabajo; un trabajo → InicioConTrabajo; y vuelve al '
    'vacío si el trabajo desaparece',
    setUp: () => when(
      () => repositorio.trabajoAsignado(),
    ).thenAnswer((_) => Stream.fromIterable([null, _trabajo, null])),
    build: () => InicioCubit(repositorio),
    expect: () => [
      const InicioSinTrabajo(),
      InicioConTrabajo(_trabajo),
      const InicioSinTrabajo(),
    ],
  );
}
