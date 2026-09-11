// Etapa 3 de HU-05: `TrabajoCubit` contra `TrabajoRepository` mockeado —
// verifica que la apertura de trabajo emita los estados correctos (cargando
// → exitoso/error) y que las excepciones se traduzcan a mensajes de error
// legibles.

import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_estado.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TrabajoRepositorioFalso extends Mock implements TrabajoRepository {}

OrdenVigente _orden({
  int id = 1,
  int loteId = 10,
  int nroAplicacion = 1,
  Decimal? loteHectareas,
}) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: loteId,
  nroAplicacion: nroAplicacion,
  litrosHa: Decimal.parse('10.00'),
  fechaEmision: '2026-09-11',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 9, 11, 12),
  loteHectareas: loteHectareas,
);

Trabajo _trabajo({
  String uuidCliente = 'uuid-1',
  int ordenId = 1,
  int loteId = 10,
  int nroAplicacion = 1,
  Decimal? hectareasDeclaradas,
}) => Trabajo(
  uuidCliente: uuidCliente,
  ordenId: ordenId,
  loteId: loteId,
  nroAplicacion: nroAplicacion,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('50'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
);

void main() {
  setUpAll(() {
    registerFallbackValue(Decimal.parse('0'));
    registerFallbackValue(DateTime.now());
  });

  late _TrabajoRepositorioFalso repositorio;

  setUp(() {
    repositorio = _TrabajoRepositorioFalso();
  });

  blocTest<TrabajoCubit, TrabajoEstado>(
    'estado inicial es TrabajoInicial',
    build: () => TrabajoCubit(repositorio),
    verify: (cubit) => expect(cubit.state, const TrabajoInicial()),
  );

  blocTest<TrabajoCubit, TrabajoEstado>(
    'abrir exitoso: emite cargando y luego exitoso con el Trabajo',
    setUp: () {
      when(
        () => repositorio.abrirTrabajo(
          ordenId: any(named: 'ordenId'),
          loteId: any(named: 'loteId'),
          nroAplicacion: any(named: 'nroAplicacion'),
          inicio: any(named: 'inicio'),
        ),
      ).thenAnswer((_) async => _trabajo());
    },
    build: () => TrabajoCubit(repositorio),
    act: (cubit) => cubit.abrir(orden: _orden()),
    expect: () => [const TrabajoCargando(), TrabajoExitoso(_trabajo())],
  );

  blocTest<TrabajoCubit, TrabajoEstado>(
    'abrir: nunca pasa hectareasDeclaradas (ni siquiera con loteHectareas '
    'presente en la orden) — el stub solo matchea una llamada SIN ese '
    'parámetro; si el Cubit lo pasara, la llamada real no matchearía este '
    'stub y el test fallaría con MissingStubError. loteHectareas es la '
    'superficie del LOTE, no lo que el piloto declaró haber cubierto',
    setUp: () {
      when(
        () => repositorio.abrirTrabajo(
          ordenId: any(named: 'ordenId'),
          loteId: any(named: 'loteId'),
          nroAplicacion: any(named: 'nroAplicacion'),
          inicio: any(named: 'inicio'),
        ),
      ).thenAnswer((_) async => _trabajo());
    },
    build: () => TrabajoCubit(repositorio),
    act: (cubit) =>
        cubit.abrir(orden: _orden(loteHectareas: Decimal.parse('100.50'))),
    expect: () => [const TrabajoCargando(), TrabajoExitoso(_trabajo())],
  );

  blocTest<TrabajoCubit, TrabajoEstado>(
    'error del repositorio: emite cargando y luego error con mensaje',
    setUp: () {
      when(
        () => repositorio.abrirTrabajo(
          ordenId: any(named: 'ordenId'),
          loteId: any(named: 'loteId'),
          nroAplicacion: any(named: 'nroAplicacion'),
          inicio: any(named: 'inicio'),
        ),
      ).thenThrow(Exception('Error en base de datos'));
    },
    build: () => TrabajoCubit(repositorio),
    act: (cubit) => cubit.abrir(orden: _orden()),
    expect: () => [
      const TrabajoCargando(),
      isA<TrabajoError>().having(
        (e) => e.mensaje,
        'mensaje',
        contains('Error al abrir trabajo'),
      ),
    ],
  );
}
