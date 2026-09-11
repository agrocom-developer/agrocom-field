// Etapa 4 de HU-05: widget test de `SesionVueloVista` — bloc real conectado
// a un `SesionRepository` mockeado (a través del Bloc), para probar los
// estados de sesión (inicial, abriendo, activa, cerrando, cerrada, error) y
// el formulario de cierre sin pasar por `SesionVueloPantalla`/GetIt.

import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

Sesion _sesionAbierta({
  String uuidCliente = 'uuid-sesion-1',
  String trabajoUuidCliente = 'uuid-trabajo-1',
  int secuencia = 1,
  int pilotoId = 1,
  Decimal? hectareasDeclaradas,
}) => Sesion(
  uuidCliente: uuidCliente,
  trabajoUuidCliente: trabajoUuidCliente,
  secuencia: secuencia,
  pilotoId: pilotoId,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('0'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
  estado: EstadoSesion.abierta,
);

Sesion _sesionCerrada({
  String uuidCliente = 'uuid-sesion-1',
  String trabajoUuidCliente = 'uuid-trabajo-1',
  int secuencia = 1,
  int pilotoId = 1,
  Decimal? hectareasDeclaradas,
  String motivoCierre = 'completado',
  Decimal? hectareasDeclaradasCierre,
  Decimal? litrosConsumidos,
}) => Sesion(
  uuidCliente: uuidCliente,
  trabajoUuidCliente: trabajoUuidCliente,
  secuencia: secuencia,
  pilotoId: pilotoId,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('0'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
  estado: EstadoSesion.cerrada,
  fin: DateTime.utc(2026, 9, 11, 12, 0),
  motivoCierre: motivoCierre,
  hectareasDeclaradasCierre:
      hectareasDeclaradasCierre ?? Decimal.parse('100.5'),
  litrosConsumidos: litrosConsumidos,
  uuidClienteCierre: 'uuid-cierre-1',
);

void main() {
  late _SesionRepositoryFalso sesionRepositorio;
  late _PersonaOperativaStoreFalso personaStore;

  setUpAll(() {
    registerFallbackValue(Decimal.zero);
  });

  setUp(() {
    sesionRepositorio = _SesionRepositoryFalso();
    personaStore = _PersonaOperativaStoreFalso();
  });

  Future<void> bombear(WidgetTester tester, SesionBloc bloc) =>
      tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SesionBloc>.value(
            value: bloc,
            child: const SesionVueloVista(),
          ),
        ),
      );

  testWidgets('estado inicial: muestra botón de abrir sesión', (tester) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boton_abrir_sesion')), findsOneWidget);
  });

  testWidgets('abriendo: muestra indicador de carga', (tester) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    when(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _sesionAbierta();
    });

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('sesión activa: muestra datos y botón de cerrar', (tester) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    when(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(find.text('Secuencia: 1'), findsOneWidget);
    expect(find.byKey(const Key('boton_cerrar_sesion')), findsOneWidget);
  });

  testWidgets('sesión cerrada: muestra resumen con motivo y hectáreas', (
    tester,
  ) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    final sesionAbierta = _sesionAbierta();
    when(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async => sesionAbierta);

    final sesionCerrada = _sesionCerrada(
      motivoCierre: 'completado',
      hectareasDeclaradasCierre: Decimal.parse('99.75'),
      litrosConsumidos: Decimal.parse('150.5'),
    );
    when(
      () => sesionRepositorio.cerrarSesion(
        sesionUuidCliente: any(named: 'sesionUuidCliente'),
        fin: any(named: 'fin'),
        motivoCierre: any(named: 'motivoCierre'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        litrosConsumidos: any(named: 'litrosConsumidos'),
      ),
    ).thenAnswer((_) async => sesionCerrada);

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
    await tester.pumpAndSettle();

    // Formulario: ingresá datos
    await tester.enterText(find.byKey(const Key('cierre_hectareas')), '99.75');
    await tester.tap(find.byKey(const Key('cierre_motivo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cierre_litros')), '150.5');
    await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
    await tester.pumpAndSettle();

    expect(find.text('Sesión cerrada'), findsOneWidget);
    expect(find.text('Motivo: Completado'), findsOneWidget);
    expect(find.text('Hectáreas declaradas (cierre): 99.75'), findsOneWidget);
    expect(find.text('Litros consumidos: 150.5'), findsOneWidget);
  });

  testWidgets('error: muestra mensaje y botón de reintentar', (tester) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => null);

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    // El mensaje aparece dos veces a propósito: el listener lo muestra como
    // SnackBar transitorio Y el builder lo deja fijo en el cuerpo (con botón
    // de reintentar) — no alcanza con el toast porque la condición bloquea
    // la pantalla hasta que se resuelva.
    expect(
      find.textContaining('Tu usuario no tiene una persona operativa asignada'),
      findsWidgets,
    );
    expect(find.byKey(const Key('boton_reintentar')), findsOneWidget);
  });

  testWidgets('validación: hectáreas obligatorias y no negativas', (
    tester,
  ) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    when(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
    await tester.pumpAndSettle();

    // Intenta cerrar sin hectáreas
    await tester.tap(find.byKey(const Key('cierre_motivo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
    await tester.pumpAndSettle();

    expect(find.text('Las hectáreas son obligatorias'), findsOneWidget);

    // Intenta con número negativo
    await tester.enterText(find.byKey(const Key('cierre_hectareas')), '-10');
    await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
    await tester.pumpAndSettle();

    expect(find.text('Las hectáreas no pueden ser negativas'), findsOneWidget);
  });

  testWidgets('motivos de cierre: todas las opciones disponibles', (
    tester,
  ) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    when(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cierre_motivo')));
    await tester.pumpAndSettle();

    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Relevo de piloto'), findsOneWidget);
    expect(find.text('Cambio de dron'), findsOneWidget);
    expect(find.text('Falla de equipo'), findsOneWidget);
    expect(find.text('Clima'), findsOneWidget);
    expect(find.text('Fin de jornada'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);
  });
}
