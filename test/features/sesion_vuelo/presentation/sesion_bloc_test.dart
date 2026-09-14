// Etapa 3 de HU-05: `SesionBloc` contra `SesionRepository` y
// `PersonaOperativaStore` mockeados — verifica que la apertura y cierre de
// sesión emitan los estados correctos, que la validación del `persona_id`
// ocurra ANTES de invocar el repositorio (sin error de base, sino una
// validación local), y que las excepciones se traduzcan a mensajes legibles.

import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/auxiliar.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_condiciones.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_estado.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_evento.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SesionRepositorioFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

// Condiciones dentro de rango por defecto — los tests de esta suite
// ejercitan el ciclo de vida del bloc, no las reglas de rango (esas están
// en `reglas_condiciones_test.dart`), así que alcanza con valores fijos que
// nunca disparen `ObservacionAgronomoRequeridaExcepcion`.
SesionAbrirSolicitada _abrirSolicitada() => SesionAbrirSolicitada(
  vientoKmh: Decimal.parse('10'),
  temperaturaC: Decimal.parse('20'),
  humedadPct: Decimal.parse('50'),
);

Sesion _sesion({
  String uuidCliente = 'sesion-uuid-1',
  String trabajoUuidCliente = 'trabajo-uuid-1',
  int secuencia = 1,
  int pilotoId = 100,
  int? auxiliarId,
  int? dronId,
  Decimal? hectareasDeclaradas,
  Decimal? hectareaInicialAcumulada,
  EstadoSesion estado = EstadoSesion.abierta,
  DateTime? inicio,
  String? uuidClienteCierre,
  Decimal? hectareasDeclaradasCierre,
  Decimal? litrosConsumidos,
}) => Sesion(
  uuidCliente: uuidCliente,
  trabajoUuidCliente: trabajoUuidCliente,
  secuencia: secuencia,
  pilotoId: pilotoId,
  auxiliarId: auxiliarId,
  dronId: dronId,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('50'),
  hectareaInicialAcumulada: hectareaInicialAcumulada,
  inicio: inicio ?? DateTime.utc(2026, 9, 11, 10, 0),
  estado: estado,
  uuidClienteCierre: uuidClienteCierre,
  hectareasDeclaradasCierre: hectareasDeclaradasCierre,
  litrosConsumidos: litrosConsumidos,
);

void main() {
  setUpAll(() {
    registerFallbackValue(Decimal.parse('0'));
    registerFallbackValue(DateTime.now());
  });

  late _SesionRepositorioFalso sesionRepositorio;
  late _PersonaOperativaStoreFalso personaOperativaStore;

  setUp(() {
    sesionRepositorio = _SesionRepositorioFalso();
    personaOperativaStore = _PersonaOperativaStoreFalso();
  });

  blocTest<SesionBloc, SesionEstado>(
    'estado inicial es SesionInicial',
    build: () => SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaOperativaStore,
      trabajoUuidCliente: 'trabajo-1',
    ),
    verify: (bloc) => expect(bloc.state, const SesionInicial()),
  );

  group('abrir sesión', () {
    blocTest<SesionBloc, SesionEstado>(
      'con pilotoId presente: emite abriendo y luego activa',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenAnswer((_) async => _sesion());
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(_abrirSolicitada()),
      expect: () => [const SesionAbriendo(), SesionActiva(_sesion())],
    );

    blocTest<SesionBloc, SesionEstado>(
      'pasa viento/temperatura/humedad/observación/firma exactos del evento '
      'al repositorio',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: Decimal.parse('20'),
            temperaturaC: Decimal.parse('35'),
            humedadPct: Decimal.parse('95'),
            observacionAgronomo: 'viento fuerte, se autoriza',
            firmaObservacion: 'Ing. Agr. Juana Pérez',
          ),
        ).thenAnswer((_) async => _sesion());
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(
        SesionAbrirSolicitada(
          vientoKmh: Decimal.parse('20'),
          temperaturaC: Decimal.parse('35'),
          humedadPct: Decimal.parse('95'),
          observacionAgronomo: 'viento fuerte, se autoriza',
          firmaObservacion: 'Ing. Agr. Juana Pérez',
        ),
      ),
      expect: () => [const SesionAbriendo(), SesionActiva(_sesion())],
    );

    blocTest<SesionBloc, SesionEstado>(
      'pasa auxiliarId/dronId/hectareaInicialAcumulada exactos del evento al '
      'repositorio (HU-07)',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
            auxiliarId: 42,
            dronId: 9,
            hectareaInicialAcumulada: Decimal.parse('100.50'),
          ),
        ).thenAnswer((_) async => _sesion());
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(
        SesionAbrirSolicitada(
          vientoKmh: Decimal.parse('10'),
          temperaturaC: Decimal.parse('20'),
          humedadPct: Decimal.parse('50'),
          auxiliarId: 42,
          dronId: 9,
          hectareaInicialAcumulada: Decimal.parse('100.50'),
        ),
      ),
      expect: () => [const SesionAbriendo(), SesionActiva(_sesion())],
    );

    blocTest<SesionBloc, SesionEstado>(
      'con pilotoId null: emite error DIRECTO sin llamar al repositorio',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => null);
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(_abrirSolicitada()),
      expect: () => [
        const SesionAbriendo(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('persona operativa asignada'),
        ),
      ],
      verify: (bloc) {
        verifyNever(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        );
      },
    );

    blocTest<SesionBloc, SesionEstado>(
      'trabajo inexistente: emite error con mensaje del repositorio',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenThrow(const TrabajoInexistenteExcepcion('trabajo-inexistente'));
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-inexistente',
      ),
      act: (bloc) => bloc.add(_abrirSolicitada()),
      expect: () => [
        const SesionAbriendo(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('El trabajo ya no existe localmente'),
        ),
      ],
    );

    blocTest<SesionBloc, SesionEstado>(
      'error genérico del repositorio: emite error con mensaje',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenThrow(Exception('Error en base de datos'));
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(_abrirSolicitada()),
      expect: () => [
        const SesionAbriendo(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('Error al abrir sesión'),
        ),
      ],
    );

    blocTest<SesionBloc, SesionEstado>(
      'condiciones fuera de rango sin observación/firma: traduce la '
      'excepción de dominio a un mensaje legible',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenThrow(const ObservacionAgronomoRequeridaExcepcion());
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(_abrirSolicitada()),
      expect: () => [
        const SesionAbriendo(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('observación y la firma del agrónomo'),
        ),
      ],
    );
  });

  group('cerrar sesión', () {
    blocTest<SesionBloc, SesionEstado>(
      'sin sesión activa: emite error DIRECTO sin llamar al repositorio',
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(
        SesionCerrarSolicitada(
          motivoCierre: 'completado',
          hectareasDeclaradas: Decimal.parse('50'),
        ),
      ),
      expect: () => [
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('No hay sesión abierta para cerrar'),
        ),
      ],
      verify: (bloc) {
        verifyNever(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
            hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
            fin: any(named: 'fin'),
            motivoCierre: any(named: 'motivoCierre'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            litrosConsumidos: any(named: 'litrosConsumidos'),
          ),
        );
      },
    );

    blocTest<SesionBloc, SesionEstado>(
      'con sesión activa: emite cerrando y luego cerrada',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
            hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
            fin: any(named: 'fin'),
            motivoCierre: any(named: 'motivoCierre'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            litrosConsumidos: any(named: 'litrosConsumidos'),
          ),
        ).thenAnswer(
          (_) async => _sesion(
            estado: EstadoSesion.cerrada,
            uuidClienteCierre: 'cierre-uuid-1',
          ),
        );
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) {
        bloc.add(_abrirSolicitada());
        bloc.add(
          SesionCerrarSolicitada(
            motivoCierre: 'completado',
            hectareasDeclaradas: Decimal.parse('50'),
          ),
        );
      },
      expect: () => [
        const SesionAbriendo(),
        SesionActiva(_sesion()),
        const SesionCerrando(),
        SesionCerrada(
          _sesion(
            estado: EstadoSesion.cerrada,
            uuidClienteCierre: 'cierre-uuid-1',
          ),
        ),
      ],
    );

    blocTest<SesionBloc, SesionEstado>(
      'con litros consumidos: se pasan al repositorio',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
            hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
            fin: any(named: 'fin'),
            motivoCierre: any(named: 'motivoCierre'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            litrosConsumidos: any(named: 'litrosConsumidos'),
          ),
        ).thenAnswer(
          (_) async => _sesion(
            estado: EstadoSesion.cerrada,
            litrosConsumidos: Decimal.parse('100'),
          ),
        );
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) {
        bloc.add(_abrirSolicitada());
        bloc.add(
          SesionCerrarSolicitada(
            motivoCierre: 'completado',
            hectareasDeclaradas: Decimal.parse('50'),
            litrosConsumidos: Decimal.parse('100'),
          ),
        );
      },
      expect: () => [
        const SesionAbriendo(),
        SesionActiva(_sesion()),
        const SesionCerrando(),
        SesionCerrada(
          _sesion(
            estado: EstadoSesion.cerrada,
            litrosConsumidos: Decimal.parse('100'),
          ),
        ),
      ],
    );

    blocTest<SesionBloc, SesionEstado>(
      'con hectareaFinalAcumulada: se pasa exacto al repositorio, sin '
      'hectareasDeclaradas (HU-07)',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenAnswer(
          (_) async =>
              _sesion(hectareaInicialAcumulada: Decimal.parse('100.50')),
        );
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
            fin: any(named: 'fin'),
            motivoCierre: any(named: 'motivoCierre'),
            hectareasDeclaradas: null,
            hectareaFinalAcumulada: Decimal.parse('120.75'),
            litrosConsumidos: any(named: 'litrosConsumidos'),
          ),
        ).thenAnswer(
          (_) async => _sesion(
            estado: EstadoSesion.cerrada,
            hectareasDeclaradasCierre: Decimal.parse('20.25'),
          ),
        );
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) {
        bloc.add(_abrirSolicitada());
        bloc.add(
          SesionCerrarSolicitada(
            motivoCierre: 'relevo_piloto',
            hectareaFinalAcumulada: Decimal.parse('120.75'),
          ),
        );
      },
      expect: () => [
        const SesionAbriendo(),
        SesionActiva(
          _sesion(hectareaInicialAcumulada: Decimal.parse('100.50')),
        ),
        const SesionCerrando(),
        SesionCerrada(
          _sesion(
            estado: EstadoSesion.cerrada,
            hectareasDeclaradasCierre: Decimal.parse('20.25'),
          ),
        ),
      ],
    );

    blocTest<SesionBloc, SesionEstado>(
      'error del repositorio al cerrar: emite error',
      setUp: () {
        when(
          () => personaOperativaStore.leerPersonaId(),
        ).thenAnswer((_) async => 100);
        when(
          () => sesionRepositorio.abrirSesion(
            trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
            pilotoId: any(named: 'pilotoId'),
            auxiliarId: any(named: 'auxiliarId'),
            dronId: any(named: 'dronId'),
            hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
            vientoKmh: any(named: 'vientoKmh'),
            temperaturaC: any(named: 'temperaturaC'),
            humedadPct: any(named: 'humedadPct'),
            observacionAgronomo: any(named: 'observacionAgronomo'),
            firmaObservacion: any(named: 'firmaObservacion'),
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
            hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
            fin: any(named: 'fin'),
            motivoCierre: any(named: 'motivoCierre'),
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            litrosConsumidos: any(named: 'litrosConsumidos'),
          ),
        ).thenThrow(Exception('Error en base de datos'));
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) {
        bloc.add(_abrirSolicitada());
        bloc.add(
          SesionCerrarSolicitada(
            motivoCierre: 'falla',
            hectareasDeclaradas: Decimal.parse('50'),
          ),
        );
      },
      expect: () => [
        const SesionAbriendo(),
        SesionActiva(_sesion()),
        const SesionCerrando(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('Error al cerrar sesión'),
        ),
      ],
    );
  });

  test('auxiliaresDisponibles delega en el repositorio (HU-07)', () async {
    final auxiliares = [const Auxiliar(id: 1, nombre: 'Ana Auxiliar')];
    when(
      () => sesionRepositorio.auxiliaresDisponibles(),
    ).thenAnswer((_) async => auxiliares);

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaOperativaStore,
      trabajoUuidCliente: 'trabajo-1',
    );
    addTearDown(bloc.close);

    final resultado = await bloc.auxiliaresDisponibles();

    expect(resultado, auxiliares);
  });
}
