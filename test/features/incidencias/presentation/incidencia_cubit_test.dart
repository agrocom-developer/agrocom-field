// HU-08: `IncidenciaCubit` contra `IncidenciaRepository`/`SelectorFoto`
// mockeados — verifica que `registrar` emita los estados correctos
// (enviando → exitosa/error), que las excepciones de dominio se traduzcan a
// mensajes legibles, y que `tomarFoto` sea un passthrough puro a
// `SelectorFoto` (no cambia el estado del Cubit).

import 'dart:typed_data';

import 'package:agrocom_field/features/incidencias/data/incidencia_repository.dart';
import 'package:agrocom_field/features/incidencias/domain/incidencia.dart';
import 'package:agrocom_field/features/incidencias/domain/reglas_incidencia.dart';
import 'package:agrocom_field/features/incidencias/domain/tipo_incidencia.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_cubit.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_estado.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _IncidenciaRepositoryFalso extends Mock implements IncidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

Incidencia _incidencia({
  String uuidCliente = 'uuid-incidencia-1',
  String sesionUuidCliente = 'uuid-sesion-1',
  TipoIncidencia tipo = TipoIncidencia.mecanica,
  String? descripcion,
}) => Incidencia(
  uuidCliente: uuidCliente,
  sesionUuidCliente: sesionUuidCliente,
  tipo: tipo,
  descripcion: descripcion,
  hora: DateTime.utc(2026, 9, 11, 10),
  evidenciaFotoUuidCliente: 'uuid-evidencia-1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime.now());
    registerFallbackValue(TipoIncidencia.otro);
  });

  late _IncidenciaRepositoryFalso repositorio;
  late _SelectorFotoFalso selectorFoto;

  setUp(() {
    repositorio = _IncidenciaRepositoryFalso();
    selectorFoto = _SelectorFotoFalso();
  });

  IncidenciaCubit crearCubit() => IncidenciaCubit(
    incidenciaRepositorio: repositorio,
    selectorFoto: selectorFoto,
    sesionUuidCliente: 'uuid-sesion-1',
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'estado inicial es IncidenciaInicial',
    build: crearCubit,
    verify: (cubit) => expect(cubit.state, const IncidenciaInicial()),
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'registrar exitoso: emite enviando y luego exitosa con la Incidencia',
    setUp: () {
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenAnswer((_) async => _incidencia());
    },
    build: crearCubit,
    act: (cubit) => cubit.registrar(
      tipo: TipoIncidencia.mecanica,
      bytesFoto: Uint8List.fromList([1, 2, 3]),
    ),
    expect: () => [
      const IncidenciaEnviando(),
      IncidenciaExitosa(_incidencia()),
    ],
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'registrar pasa sesionUuidCliente, tipo, descripcion, hora y bytesFoto '
    'exactos al repositorio',
    setUp: () {
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenAnswer((_) async => _incidencia());
    },
    build: crearCubit,
    act: (cubit) => cubit.registrar(
      tipo: TipoIncidencia.clima,
      descripcion: 'Ráfagas fuertes',
      bytesFoto: Uint8List.fromList([9, 9, 9]),
    ),
    verify: (_) {
      verify(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: 'uuid-sesion-1',
          tipo: TipoIncidencia.clima,
          descripcion: 'Ráfagas fuertes',
          hora: any(named: 'hora'),
          bytesFoto: Uint8List.fromList([9, 9, 9]),
        ),
      ).called(1);
    },
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'sesión inexistente: emite enviando y luego error con mensaje legible',
    setUp: () {
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenThrow(const SesionInexistenteExcepcion('uuid-sesion-1'));
    },
    build: crearCubit,
    act: (cubit) => cubit.registrar(
      tipo: TipoIncidencia.otro,
      bytesFoto: Uint8List.fromList([1]),
    ),
    expect: () => [
      const IncidenciaEnviando(),
      isA<IncidenciaError>().having(
        (e) => e.mensaje,
        'mensaje',
        contains('ya no existe'),
      ),
    ],
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'sesión cerrada: emite enviando y luego error con mensaje legible',
    setUp: () {
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenThrow(const SesionCerradaExcepcion('uuid-sesion-1'));
    },
    build: crearCubit,
    act: (cubit) => cubit.registrar(
      tipo: TipoIncidencia.otro,
      bytesFoto: Uint8List.fromList([1]),
    ),
    expect: () => [
      const IncidenciaEnviando(),
      isA<IncidenciaError>().having(
        (e) => e.mensaje,
        'mensaje',
        contains('ya está cerrada'),
      ),
    ],
  );

  blocTest<IncidenciaCubit, IncidenciaEstado>(
    'error inesperado del repositorio: emite enviando y luego error genérico',
    setUp: () {
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenThrow(Exception('Error en base de datos'));
    },
    build: crearCubit,
    act: (cubit) => cubit.registrar(
      tipo: TipoIncidencia.otro,
      bytesFoto: Uint8List.fromList([1]),
    ),
    expect: () => [
      const IncidenciaEnviando(),
      isA<IncidenciaError>().having(
        (e) => e.mensaje,
        'mensaje',
        contains('Error al registrar la incidencia'),
      ),
    ],
  );

  test('tomarFoto delega en SelectorFoto y no cambia el estado', () async {
    final bytes = Uint8List.fromList([4, 5, 6]);
    when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => bytes);
    final cubit = crearCubit();
    addTearDown(cubit.close);

    final resultado = await cubit.tomarFoto();

    expect(resultado, bytes);
    expect(cubit.state, const IncidenciaInicial());
  });

  test('tomarFoto devuelve null si el piloto cancela la captura', () async {
    when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => null);
    final cubit = crearCubit();
    addTearDown(cubit.close);

    final resultado = await cubit.tomarFoto();

    expect(resultado, isNull);
  });
}
