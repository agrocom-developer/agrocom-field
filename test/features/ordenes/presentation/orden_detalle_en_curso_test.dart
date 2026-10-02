// Tarea 28: «Abrir trabajo» del detalle de orden con algo en curso — misma
// regla que «Crear aplicación» en «Inicio»: deshabilitado con el motivo y un
// acceso a lo que está en curso; sin nada en curso, habilitado como antes.

import 'dart:async';

import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/features/ordenes/presentation/orden_detalle_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_apertura.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo_en_curso.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

const _uuidEnCurso = 'uuid-trabajo-en-curso';

final _orden = OrdenVigente(
  id: 9,
  contratoId: 1,
  loteId: 3,
  nroAplicacion: 2,
  fechaEmision: '2026-10-01',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 10, 1),
);

TrabajoEnCurso _enCurso({String? sesion}) => TrabajoEnCurso(
  trabajoUuidCliente: _uuidEnCurso,
  sesionUuidCliente: sesion,
  inicio: DateTime(2026, 10, 2, 9),
);

void main() {
  late _TrabajoRepositoryFalso trabajoRepositorio;
  late _SesionRepositoryFalso sesionRepositorio;
  late List<String> sesionesPedidas;

  setUp(() {
    trabajoRepositorio = _TrabajoRepositoryFalso();
    sesionRepositorio = _SesionRepositoryFalso();
    sesionesPedidas = [];
    when(
      () => sesionRepositorio.sesionAbiertaDeTrabajo(any()),
    ).thenAnswer((_) async => null);
    when(
      () => sesionRepositorio.restriccionAperturaDeTrabajo(any()),
    ).thenAnswer((_) async => RestriccionApertura.ninguna);
  });

  Future<void> bombear(
    WidgetTester tester,
    Stream<TrabajoEnCurso?> enCurso,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => trabajoRepositorio.enCurso()).thenAnswer((_) => enCurso);
    TrabajoCubit crearTrabajoCubit() => TrabajoCubit(
      trabajoRepositorio,
      evidenciaRepositorio: _EvidenciaRepositoryFalso(),
      selectorFoto: _SelectorFotoFalso(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden,
          flavor: Flavor.piloto,
          crearTrabajoCubit: crearTrabajoCubit,
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
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  VoidCallback? abrirTrabajo(WidgetTester tester) => tester
      .widget<BotonPrimarioCampo>(find.byKey(const Key('boton_abrir_trabajo')))
      .onPressed;

  String motivo(WidgetTester tester) => tester
      .widget<NotaInlineCampo>(find.byKey(const Key('orden_abrir_bloqueado')))
      .texto;

  testWidgets('con una sesión abierta: «Abrir trabajo» deshabilitado, con el '
      'motivo y «Volver a la sesión»', (tester) async {
    await bombear(tester, Stream.value(_enCurso(sesion: 'uuid-sesion')));

    expect(abrirTrabajo(tester), isNull);
    expect(motivo(tester), contains('sesión en curso'));
    expect(find.text('Volver a la sesión'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton_volver_en_curso')));
    await tester.pumpAndSettle();

    expect(find.byType(SesionVueloPantalla), findsOneWidget);
    expect(sesionesPedidas, [_uuidEnCurso]);
    verifyNever(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        inicio: any(named: 'inicio'),
      ),
    );
  });

  testWidgets('con un trabajo abierto sin sesión: «Abrir trabajo» '
      'deshabilitado, con el motivo y «Volver al trabajo»', (tester) async {
    await bombear(tester, Stream.value(_enCurso()));

    expect(abrirTrabajo(tester), isNull);
    expect(motivo(tester), contains('Tenés un trabajo en curso'));
    expect(motivo(tester), contains('abrir otro trabajo'));
    expect(find.text('Volver al trabajo'), findsOneWidget);
  });

  testWidgets('sin nada en curso: habilitado, sin motivo; y se deshabilita '
      'solo cuando aparece algo en curso', (tester) async {
    final enCurso = StreamController<TrabajoEnCurso?>();
    addTearDown(enCurso.close);
    enCurso.add(null);
    await bombear(tester, enCurso.stream);

    expect(abrirTrabajo(tester), isNotNull);
    expect(find.byKey(const Key('orden_abrir_bloqueado')), findsNothing);
    expect(find.byKey(const Key('boton_volver_en_curso')), findsNothing);

    enCurso.add(_enCurso());
    await tester.pumpAndSettle();

    expect(abrirTrabajo(tester), isNull);
  });
}
