// Tarea 27: «Inicio» con algo en curso en el dispositivo — la tarjeta
// «Sesión en curso»/«Trabajo en curso» arriba de todo (también con el
// trabajo retirado del catálogo), el botón que vuelve a la pantalla de
// sesión de ESE trabajo, y «Crear aplicación» deshabilitado con el motivo
// cuando lo en curso es otro trabajo.

import 'dart:async';

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:agrocom_field/features/inicio/domain/trabajo_en_curso.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_cubit.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _InicioRepositoryFalso extends Mock implements InicioRepository {}

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

const _uuidAsignado = 'uuid-panel-42';
const _uuidOtro = 'uuid-trabajo-de-la-app';

TrabajoAsignado _asignado() => TrabajoAsignado(
  id: 42,
  uuidCliente: _uuidAsignado,
  ordenId: 1,
  loteId: 3,
  hectareasDeclaradas: Decimal.parse('42.5'),
  equipoTrabajoId: 7,
  updatedAt: DateTime.utc(2026, 9, 22),
  loteCodigo: 'L-14',
  nroAplicacion: 2,
);

TrabajoEnCurso _enCurso({
  String trabajo = _uuidOtro,
  String? sesion = 'uuid-sesion-abierta',
  String? motivoRetiro,
}) => TrabajoEnCurso(
  trabajoUuidCliente: trabajo,
  sesionUuidCliente: sesion,
  inicio: DateTime(2026, 10, 1, 9, 30),
  loteCodigo: 'L-07',
  motivoRetiro: motivoRetiro,
);

void main() {
  late _InicioRepositoryFalso inicioRepositorio;
  late _SesionRepositoryFalso sesionRepositorio;
  late List<String> sesionesPedidas;

  setUp(() {
    inicioRepositorio = _InicioRepositoryFalso();
    sesionRepositorio = _SesionRepositoryFalso();
    sesionesPedidas = [];
    when(
      () => sesionRepositorio.sesionAbiertaDeTrabajo(any()),
    ).thenAnswer((_) async => null);
  });

  Future<void> bombear(
    WidgetTester tester, {
    required Stream<TrabajoAsignado?> asignado,
    required Stream<TrabajoEnCurso?> enCurso,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => inicioRepositorio.trabajoAsignado()).thenAnswer((_) => asignado);
    when(() => inicioRepositorio.enCurso()).thenAnswer((_) => enCurso);
    await tester.pumpWidget(
      MaterialApp(
        theme: AgrocomThemeCampo.construir(),
        home: InicioPantalla(
          crearCubit: () => InicioCubit(inicioRepositorio),
          crearTrabajoCubit: () => TrabajoCubit(
            _TrabajoRepositoryFalso(),
            evidenciaRepositorio: _EvidenciaRepositoryFalso(),
            selectorFoto: _SelectorFotoFalso(),
          ),
          crearSesionBloc: (trabajoUuidCliente) {
            sesionesPedidas.add(trabajoUuidCliente);
            return SesionBloc(
              sesionRepositorio: sesionRepositorio,
              personaOperativaStore: _PersonaOperativaStoreFalso(),
              trabajoUuidCliente: trabajoUuidCliente,
            );
          },
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
          construirOrdenes: (_) =>
              const Scaffold(key: Key('pantalla_ordenes_falsa')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String? texto(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data;

  VoidCallback? crearAplicacion(WidgetTester tester) => tester
      .widget<BotonPrimarioCampo>(
        find.byKey(const Key('boton_crear_aplicacion')),
      )
      .onPressed;

  testWidgets('trabajo retirado con sesión abierta: la tarjeta se ve arriba '
      'con el motivo, y vuelve a ESA sesión', (tester) async {
    when(() => sesionRepositorio.sesionAbiertaDeTrabajo(_uuidOtro)).thenAnswer(
      (_) async => Sesion(
        uuidCliente: 'uuid-sesion-abierta',
        trabajoUuidCliente: _uuidOtro,
        secuencia: 2,
        pilotoId: 7,
        hectareasDeclaradas: Decimal.zero,
        inicio: DateTime.utc(2026, 10, 1, 9, 30),
        estado: EstadoSesion.abierta,
      ),
    );
    // Retirado: ya no es «el trabajo asignado», pero sigue en curso.
    await bombear(
      tester,
      asignado: Stream.value(null),
      enCurso: Stream.value(_enCurso(motivoRetiro: 'reasignado')),
    );

    expect(find.byKey(const Key('inicio_en_curso')), findsOneWidget);
    expect(texto(tester, 'inicio_en_curso_titulo'), 'SESIÓN EN CURSO');
    expect(texto(tester, 'inicio_en_curso_lote'), 'L-07');
    expect(texto(tester, 'inicio_en_curso_inicio'), 'Inicio 01/10 09:30');
    expect(
      tester
          .widget<NotaInlineCampo>(
            find.byKey(const Key('inicio_en_curso_retiro')),
          )
          .texto,
      'El trabajo fue reasignado a otro equipo.',
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('inicio_en_curso'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('inicio_sin_trabajo'))).dy,
      ),
      reason: 'arriba de todo',
    );

    await tester.tap(find.byKey(const Key('boton_volver_en_curso')));
    await tester.pumpAndSettle();

    expect(find.byType(SesionVueloPantalla), findsOneWidget);
    expect(sesionesPedidas, [_uuidOtro]);
    expect(find.text('Sesión activa'), findsOneWidget);
  });

  testWidgets('trabajo en curso sin sesión: «Trabajo en curso», sin motivo '
      'si sigue vigente', (tester) async {
    await bombear(
      tester,
      asignado: Stream.value(null),
      enCurso: Stream.value(_enCurso(sesion: null)),
    );

    expect(texto(tester, 'inicio_en_curso_titulo'), 'TRABAJO EN CURSO');
    expect(find.text('Volver al trabajo'), findsOneWidget);
    expect(find.byKey(const Key('inicio_en_curso_retiro')), findsNothing);

    await tester.tap(find.byKey(const Key('boton_volver_en_curso')));
    await tester.pumpAndSettle();
    expect(sesionesPedidas, [_uuidOtro]);
    expect(find.byKey(const Key('boton_abrir_sesion')), findsOneWidget);
  });

  testWidgets('con algo en curso en OTRO trabajo, «Crear aplicación» queda '
      'deshabilitado con el motivo, y el «+» vuelve a lo en curso', (
    tester,
  ) async {
    await bombear(
      tester,
      asignado: Stream.value(_asignado()),
      enCurso: Stream.value(_enCurso()),
    );

    expect(crearAplicacion(tester), isNull);
    expect(
      tester
          .widget<NotaInlineCampo>(
            find.byKey(const Key('inicio_crear_bloqueado')),
          )
          .texto,
      contains('sesión en curso en otro trabajo'),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(sesionesPedidas, [_uuidOtro]);
  });

  testWidgets('cuando lo en curso se cierra, «Crear aplicación» se habilita '
      'solo', (tester) async {
    final enCurso = StreamController<TrabajoEnCurso?>();
    addTearDown(enCurso.close);
    await bombear(
      tester,
      asignado: Stream.value(_asignado()),
      enCurso: enCurso.stream,
    );
    enCurso.add(_enCurso(sesion: null));
    await tester.pumpAndSettle();
    expect(crearAplicacion(tester), isNull);

    enCurso.add(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inicio_en_curso')), findsNothing);
    expect(find.byKey(const Key('inicio_crear_bloqueado')), findsNothing);
    expect(crearAplicacion(tester), isNotNull);
  });

  testWidgets('con el MISMO trabajo en curso, «Crear aplicación» sigue '
      'habilitado: lleva a la misma pantalla de sesión', (tester) async {
    await bombear(
      tester,
      asignado: Stream.value(_asignado()),
      enCurso: Stream.value(_enCurso(trabajo: _uuidAsignado)),
    );

    expect(find.byKey(const Key('inicio_en_curso')), findsOneWidget);
    expect(crearAplicacion(tester), isNotNull);
    expect(find.byKey(const Key('inicio_crear_bloqueado')), findsNothing);
  });
}
