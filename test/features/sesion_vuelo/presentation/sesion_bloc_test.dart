// Etapa 3 de HU-05: `SesionBloc` contra `SesionRepository` y
// `PersonaOperativaStore` mockeados — verifica que la apertura y cierre de
// sesión emitan los estados correctos, que la validación del `persona_id`
// ocurra ANTES de invocar el repositorio (sin error de base, sino una
// validación local), y que las excepciones se traduzcan a mensajes legibles.

import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
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

Sesion _sesion({
  String uuidCliente = 'sesion-uuid-1',
  String trabajoUuidCliente = 'trabajo-uuid-1',
  int secuencia = 1,
  int pilotoId = 100,
  Decimal? hectareasDeclaradas,
  EstadoSesion estado = EstadoSesion.abierta,
  DateTime? inicio,
  String? uuidClienteCierre,
  Decimal? litrosConsumidos,
}) => Sesion(
  uuidCliente: uuidCliente,
  trabajoUuidCliente: trabajoUuidCliente,
  secuencia: secuencia,
  pilotoId: pilotoId,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('50'),
  inicio: inicio ?? DateTime.utc(2026, 9, 11, 10, 0),
  estado: estado,
  uuidClienteCierre: uuidClienteCierre,
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
          ),
        ).thenAnswer((_) async => _sesion());
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(const SesionAbrirSolicitada()),
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
      act: (bloc) => bloc.add(const SesionAbrirSolicitada()),
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
          ),
        ).thenThrow(const TrabajoInexistenteExcepcion('trabajo-inexistente'));
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-inexistente',
      ),
      act: (bloc) => bloc.add(const SesionAbrirSolicitada()),
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
          ),
        ).thenThrow(Exception('Error en base de datos'));
      },
      build: () => SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaOperativaStore,
        trabajoUuidCliente: 'trabajo-1',
      ),
      act: (bloc) => bloc.add(const SesionAbrirSolicitada()),
      expect: () => [
        const SesionAbriendo(),
        isA<SesionError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('Error al abrir sesión'),
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
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
        bloc.add(const SesionAbrirSolicitada());
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
            hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
            inicio: any(named: 'inicio'),
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
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
        bloc.add(const SesionAbrirSolicitada());
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
      'error del repositorio al cerrar: emite error',
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
          ),
        ).thenAnswer((_) async => _sesion());
        when(
          () => sesionRepositorio.cerrarSesion(
            sesionUuidCliente: any(named: 'sesionUuidCliente'),
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
        bloc.add(const SesionAbrirSolicitada());
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
}
