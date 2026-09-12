// Etapa 3 de HU-05: `TrabajoCubit` contra `TrabajoRepository` mockeado —
// verifica que la apertura de trabajo emita los estados correctos (cargando
// → exitoso/error) y que las excepciones se traduzcan a mensajes de error
// legibles.
//
// HU-09 (cierre de trabajo) agrega, más abajo: `cerrar` contra
// `EvidenciaRepository`/`TrabajoRepository` mockeados (cargando → cerrado/
// error), y que `tomarFotoCampo` sea un passthrough puro a `SelectorFoto`
// (no cambia el estado del Cubit) — mismo patrón que `incidencia_cubit_test.dart`.

import 'dart:typed_data';

import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_estado.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TrabajoRepositorioFalso extends Mock implements TrabajoRepository {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

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
  EstadoTrabajo estado = EstadoTrabajo.abierto,
  DateTime? fin,
  Decimal? litrosSobrante,
  String? evidenciaImagenCampoUuidCliente,
  String? uuidClienteCierre,
}) => Trabajo(
  uuidCliente: uuidCliente,
  ordenId: ordenId,
  loteId: loteId,
  nroAplicacion: nroAplicacion,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('50'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
  estado: estado,
  fin: fin,
  litrosSobrante: litrosSobrante,
  evidenciaImagenCampoUuidCliente: evidenciaImagenCampoUuidCliente,
  uuidClienteCierre: uuidClienteCierre,
);

void main() {
  setUpAll(() {
    registerFallbackValue(Decimal.parse('0'));
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Uint8List(0));
  });

  late _TrabajoRepositorioFalso repositorio;
  late _EvidenciaRepositoryFalso evidenciaRepositorio;
  late _SelectorFotoFalso selectorFoto;

  setUp(() {
    repositorio = _TrabajoRepositorioFalso();
    evidenciaRepositorio = _EvidenciaRepositoryFalso();
    selectorFoto = _SelectorFotoFalso();
  });

  TrabajoCubit crearCubit() => TrabajoCubit(
    repositorio,
    evidenciaRepositorio: evidenciaRepositorio,
    selectorFoto: selectorFoto,
  );

  blocTest<TrabajoCubit, TrabajoEstado>(
    'estado inicial es TrabajoInicial',
    build: crearCubit,
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
    build: crearCubit,
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
    build: crearCubit,
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
    build: crearCubit,
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

  group('cerrar', () {
    blocTest<TrabajoCubit, TrabajoEstado>(
      'exitoso: captura la evidencia, emite cerrando y luego cerrado con el '
      'Trabajo',
      setUp: () {
        when(
          () => evidenciaRepositorio.capturarEvidencia(
            bytesOriginales: any(named: 'bytesOriginales'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
          ),
        ).thenAnswer((_) async => 'uuid-evidencia-1');
        when(
          () => repositorio.cerrarTrabajo(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            fin: any(named: 'fin'),
            litrosSobrante: any(named: 'litrosSobrante'),
            evidenciaImagenCampoUuidCliente: any(
              named: 'evidenciaImagenCampoUuidCliente',
            ),
          ),
        ).thenAnswer(
          (_) async => _trabajo(
            estado: EstadoTrabajo.cerrado,
            evidenciaImagenCampoUuidCliente: 'uuid-evidencia-1',
            uuidClienteCierre: 'uuid-cierre-1',
          ),
        );
      },
      build: crearCubit,
      act: (cubit) => cubit.cerrar(
        trabajoUuidCliente: 'uuid-1',
        bytesFoto: Uint8List.fromList([1, 2, 3]),
      ),
      expect: () => [
        const TrabajoCerrando(),
        TrabajoCerrado(
          _trabajo(
            estado: EstadoTrabajo.cerrado,
            evidenciaImagenCampoUuidCliente: 'uuid-evidencia-1',
            uuidClienteCierre: 'uuid-cierre-1',
          ),
        ),
      ],
    );

    blocTest<TrabajoCubit, TrabajoEstado>(
      'pasa tipo imagen_campo a EvidenciaRepository, y el uuid_cliente '
      'resultante junto con trabajoUuidCliente/fin/litrosSobrante exactos a '
      'TrabajoRepository',
      setUp: () {
        when(
          () => evidenciaRepositorio.capturarEvidencia(
            bytesOriginales: any(named: 'bytesOriginales'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
          ),
        ).thenAnswer((_) async => 'uuid-evidencia-2');
        when(
          () => repositorio.cerrarTrabajo(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            fin: any(named: 'fin'),
            litrosSobrante: any(named: 'litrosSobrante'),
            evidenciaImagenCampoUuidCliente: any(
              named: 'evidenciaImagenCampoUuidCliente',
            ),
          ),
        ).thenAnswer((_) async => _trabajo(estado: EstadoTrabajo.cerrado));
      },
      build: crearCubit,
      act: (cubit) => cubit.cerrar(
        trabajoUuidCliente: 'uuid-trabajo-x',
        litrosSobrante: Decimal.parse('7.50'),
        bytesFoto: Uint8List.fromList([9, 9]),
      ),
      verify: (_) {
        verify(
          () => evidenciaRepositorio.capturarEvidencia(
            bytesOriginales: Uint8List.fromList([9, 9]),
            tipo: 'imagen_campo',
            fecha: any(named: 'fecha'),
          ),
        ).called(1);
        verify(
          () => repositorio.cerrarTrabajo(
            trabajoUuidCliente: 'uuid-trabajo-x',
            fin: any(named: 'fin'),
            litrosSobrante: Decimal.parse('7.50'),
            evidenciaImagenCampoUuidCliente: 'uuid-evidencia-2',
          ),
        ).called(1);
      },
    );

    blocTest<TrabajoCubit, TrabajoEstado>(
      'excepción del repositorio (dominio o inesperada): emite cerrando y '
      'luego error con mensaje legible — TrabajoCubit no distingue el tipo '
      '(a diferencia de IncidenciaCubit), porque la UI ya bloquea el botón '
      'sin foto y el repositorio es la última línea de defensa, no un caso '
      'esperable en el camino feliz',
      setUp: () {
        when(
          () => evidenciaRepositorio.capturarEvidencia(
            bytesOriginales: any(named: 'bytesOriginales'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
          ),
        ).thenAnswer((_) async => 'uuid-evidencia-3');
        when(
          () => repositorio.cerrarTrabajo(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            fin: any(named: 'fin'),
            litrosSobrante: any(named: 'litrosSobrante'),
            evidenciaImagenCampoUuidCliente: any(
              named: 'evidenciaImagenCampoUuidCliente',
            ),
          ),
        ).thenThrow(const EvidenciaImagenCampoRequeridaExcepcion());
      },
      build: crearCubit,
      act: (cubit) => cubit.cerrar(
        trabajoUuidCliente: 'uuid-1',
        bytesFoto: Uint8List.fromList([1]),
      ),
      expect: () => [
        const TrabajoCerrando(),
        isA<TrabajoError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('Error al cerrar trabajo'),
        ),
      ],
    );
  });

  test('tomarFotoCampo delega en SelectorFoto y no cambia el estado', () async {
    final bytes = Uint8List.fromList([4, 5, 6]);
    when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => bytes);
    final cubit = crearCubit();
    addTearDown(cubit.close);

    final resultado = await cubit.tomarFotoCampo();

    expect(resultado, bytes);
    expect(cubit.state, const TrabajoInicial());
  });

  test(
    'tomarFotoCampo devuelve null si el piloto cancela la captura',
    () async {
      when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => null);
      final cubit = crearCubit();
      addTearDown(cubit.close);

      final resultado = await cubit.tomarFotoCampo();

      expect(resultado, isNull);
    },
  );
}
