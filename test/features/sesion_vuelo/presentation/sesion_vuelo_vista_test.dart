// Etapa 4 de HU-05: widget test de `SesionVueloVista` — bloc real conectado
// a un `SesionRepository` mockeado (a través del Bloc), para probar los
// estados de sesión (inicial, abriendo, activa, cerrando, cerrada, error) y
// el formulario de cierre sin pasar por `SesionVueloPantalla`/GetIt.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/features/incidencias/data/incidencia_repository.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_cubit.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/auxiliar.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _IncidenciaRepositoryFalso extends Mock implements IncidenciaRepository {}

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

// PNG 1x1 real (no bytes arbitrarios): `Image.memory` en el preview del
// diálogo de cierre de trabajo decodifica de verdad — bytes inválidos hacen
// que el widget test falle por la excepción asincrónica del decodificador de
// imagen, no por el fixture. Mismo bytes que `incidencia_vista_test.dart`.
final _bytesFotoValidos = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42Y'
  'AAAAASUVORK5CYII=',
);

Sesion _sesionAbierta({
  String uuidCliente = 'uuid-sesion-1',
  String trabajoUuidCliente = 'uuid-trabajo-1',
  int secuencia = 1,
  int pilotoId = 1,
  Decimal? hectareasDeclaradas,
  Decimal? hectareaInicialAcumulada,
}) => Sesion(
  uuidCliente: uuidCliente,
  trabajoUuidCliente: trabajoUuidCliente,
  secuencia: secuencia,
  pilotoId: pilotoId,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('0'),
  hectareaInicialAcumulada: hectareaInicialAcumulada,
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
  late _TrabajoRepositoryFalso trabajoRepositorio;
  late _EvidenciaRepositoryFalso evidenciaRepositorio;
  late _SelectorFotoFalso selectorFotoTrabajo;

  setUpAll(() {
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    sesionRepositorio = _SesionRepositoryFalso();
    personaStore = _PersonaOperativaStoreFalso();
    trabajoRepositorio = _TrabajoRepositoryFalso();
    evidenciaRepositorio = _EvidenciaRepositoryFalso();
    selectorFotoTrabajo = _SelectorFotoFalso();
    // Por defecto sin auxiliares — los tests de HU-07 que necesitan poblar
    // el dropdown lo re-stubean explícitamente.
    when(
      () => sesionRepositorio.auxiliaresDisponibles(),
    ).thenAnswer((_) async => const <Auxiliar>[]);
  });

  Future<void> bombear(
    WidgetTester tester,
    SesionBloc bloc, {
    IncidenciaCubit Function(String sesionUuidCliente)? crearIncidenciaCubit,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SesionBloc>.value(value: bloc),
          // HU-09: `SesionVueloVista` lee `TrabajoCubit` del árbol (para el
          // botón "Cerrar trabajo" en el estado `SesionCerrada`). El grupo
          // 'cerrar trabajo (HU-09)' más abajo sí ejercita el cierre en sí,
          // stubeando `trabajoRepositorio`/`selectorFotoTrabajo`; el resto de
          // los tests de este archivo solo necesitan que el `BlocProvider`
          // exista para no explotar con `ProviderNotFoundException` al
          // renderizar el estado `SesionCerrada`.
          BlocProvider<TrabajoCubit>(
            create: (_) => TrabajoCubit(
              trabajoRepositorio,
              evidenciaRepositorio: evidenciaRepositorio,
              selectorFoto: selectorFotoTrabajo,
            ),
          ),
        ],
        child: SesionVueloVista(
          crearIncidenciaCubit:
              crearIncidenciaCubit ??
              (_) => throw UnimplementedError('stub no invocado'),
        ),
      ),
    ),
  );

  /// Abre el formulario de condiciones (tocando `boton_abrir_sesion` o
  /// `boton_reintentar`, según [key]), completa viento/temperatura/humedad
  /// (y observación/firma si se pasan) y confirma. No asume que el
  /// formulario siga abierto al final: falla la validación y no confirma
  /// si algún campo obligatorio quedó vacío.
  Future<void> completarFormularioApertura(
    WidgetTester tester, {
    String viento = '10',
    String temperatura = '20',
    String humedad = '50',
    String? observacion,
    String? firma,
    String? auxiliarNombre,
    String? dronId,
    String? hectareaInicialAcumulada,
    String key = 'boton_abrir_sesion',
  }) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('apertura_viento')), viento);
    await tester.enterText(
      find.byKey(const Key('apertura_temperatura')),
      temperatura,
    );
    await tester.enterText(find.byKey(const Key('apertura_humedad')), humedad);
    await tester.pumpAndSettle();

    if (observacion != null) {
      await tester.enterText(
        find.byKey(const Key('apertura_observacion')),
        observacion,
      );
    }
    if (firma != null) {
      await tester.enterText(find.byKey(const Key('apertura_firma')), firma);
    }
    if (auxiliarNombre != null) {
      await tester.tap(find.byKey(const Key('apertura_auxiliar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(auxiliarNombre).last);
      await tester.pumpAndSettle();
    }
    if (dronId != null) {
      await tester.enterText(find.byKey(const Key('apertura_dron_id')), dronId);
    }
    if (hectareaInicialAcumulada != null) {
      await tester.enterText(
        find.byKey(const Key('apertura_hectarea_inicial_acumulada')),
        hectareaInicialAcumulada,
      );
    }

    await tester.tap(find.byKey(const Key('boton_confirmar_apertura')));
    await tester.pumpAndSettle();
  }

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
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('apertura_viento')), '10');
    await tester.enterText(find.byKey(const Key('apertura_temperatura')), '20');
    await tester.enterText(find.byKey(const Key('apertura_humedad')), '50');
    await tester.tap(find.byKey(const Key('boton_confirmar_apertura')));
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
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await completarFormularioApertura(tester);

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(find.text('Secuencia: 1'), findsOneWidget);
    expect(find.byKey(const Key('boton_cerrar_sesion')), findsOneWidget);
  });

  testWidgets(
    'sesión activa: "Reportar incidencia" navega a IncidenciaPantalla con '
    'el uuid_cliente de ESTA sesión',
    (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
      ).thenAnswer((_) async => _sesionAbierta(uuidCliente: 'uuid-sesion-x'));

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      String? sesionUuidClienteRecibido;
      final incidenciaRepositorio = _IncidenciaRepositoryFalso();
      final selectorFoto = _SelectorFotoFalso();

      await bombear(
        tester,
        bloc,
        crearIncidenciaCubit: (sesionUuidCliente) {
          sesionUuidClienteRecibido = sesionUuidCliente;
          return IncidenciaCubit(
            incidenciaRepositorio: incidenciaRepositorio,
            selectorFoto: selectorFoto,
            sesionUuidCliente: sesionUuidCliente,
          );
        },
      );
      await completarFormularioApertura(tester);

      await tester.tap(find.byKey(const Key('boton_reportar_incidencia')));
      await tester.pumpAndSettle();

      expect(find.byType(IncidenciaVista), findsOneWidget);
      expect(sesionUuidClienteRecibido, 'uuid-sesion-x');
    },
  );

  testWidgets('sesión cerrada: muestra resumen con motivo y hectáreas', (
    tester,
  ) async {
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
    final sesionAbierta = _sesionAbierta();
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
    ).thenAnswer((_) async => sesionAbierta);

    final sesionCerrada = _sesionCerrada(
      motivoCierre: 'completado',
      hectareasDeclaradasCierre: Decimal.parse('99.75'),
      litrosConsumidos: Decimal.parse('150.5'),
    );
    when(
      () => sesionRepositorio.cerrarSesion(
        sesionUuidCliente: any(named: 'sesionUuidCliente'),
        hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
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
    await completarFormularioApertura(tester);

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

  group('cerrar trabajo (HU-09)', () {
    /// Lleva la pantalla hasta el estado `SesionCerrada` (abre y cierra una
    /// sesión) — mismo camino que 'sesión cerrada: muestra resumen...' de
    /// arriba, factorizado para no repetirlo en cada test de este grupo.
    Future<void> bombearHastaSesionCerrada(WidgetTester tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
        (_) async => _sesionAbierta(trabajoUuidCliente: 'uuid-trabajo-1'),
      );
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
        (_) async => _sesionCerrada(trabajoUuidCliente: 'uuid-trabajo-1'),
      );

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await completarFormularioApertura(tester);

      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('cierre_hectareas')), '10');
      await tester.tap(find.byKey(const Key('cierre_motivo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completado'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
      await tester.pumpAndSettle();

      expect(find.text('Sesión cerrada'), findsOneWidget);
    }

    testWidgets(
      'botón deshabilitado hasta tomar la foto — "sin captura no cierra"',
      (tester) async {
        await bombearHastaSesionCerrada(tester);

        await tester.tap(find.byKey(const Key('boton_cerrar_trabajo')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'La foto del campo es obligatoria — sin captura no se puede '
            'cerrar el trabajo.',
          ),
          findsOneWidget,
        );
        final botonConfirmar = tester.widget<FilledButton>(
          find.byKey(const Key('boton_confirmar_cierre_trabajo')),
        );
        expect(botonConfirmar.onPressed, isNull);
      },
    );

    testWidgets('con foto: captura evidencia imagen_campo, cierra el trabajo y '
        'muestra confirmación', (tester) async {
      await bombearHastaSesionCerrada(tester);

      final bytesFoto = _bytesFotoValidos;
      when(
        () => selectorFotoTrabajo.tomarFoto(),
      ).thenAnswer((_) async => bytesFoto);
      when(
        () => evidenciaRepositorio.capturarEvidencia(
          bytesOriginales: any(named: 'bytesOriginales'),
          tipo: any(named: 'tipo'),
          fecha: any(named: 'fecha'),
        ),
      ).thenAnswer((_) async => 'uuid-evidencia-campo-1');
      when(
        () => trabajoRepositorio.cerrarTrabajo(
          trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
          fin: any(named: 'fin'),
          litrosSobrante: any(named: 'litrosSobrante'),
          evidenciaImagenCampoUuidCliente: any(
            named: 'evidenciaImagenCampoUuidCliente',
          ),
        ),
      ).thenAnswer(
        (_) async => Trabajo(
          uuidCliente: 'uuid-trabajo-1',
          ordenId: 1,
          loteId: 1,
          nroAplicacion: 1,
          hectareasDeclaradas: Decimal.parse('0'),
          inicio: DateTime.utc(2026, 9, 11, 8),
          estado: EstadoTrabajo.cerrado,
        ),
      );

      await tester.tap(find.byKey(const Key('boton_cerrar_trabajo')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_tomar_foto_campo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preview_foto_campo')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('cierre_trabajo_litros_sobrante')),
        '5.25',
      );
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre_trabajo')));
      await tester.pumpAndSettle();

      verify(
        () => evidenciaRepositorio.capturarEvidencia(
          bytesOriginales: bytesFoto,
          tipo: 'imagen_campo',
          fecha: any(named: 'fecha'),
        ),
      ).called(1);
      verify(
        () => trabajoRepositorio.cerrarTrabajo(
          trabajoUuidCliente: 'uuid-trabajo-1',
          fin: any(named: 'fin'),
          litrosSobrante: Decimal.parse('5.25'),
          evidenciaImagenCampoUuidCliente: 'uuid-evidencia-campo-1',
        ),
      ).called(1);
      expect(find.text('Trabajo cerrado'), findsWidgets);
    });

    testWidgets('error al cerrar trabajo: muestra SnackBar', (tester) async {
      await bombearHastaSesionCerrada(tester);

      when(
        () => selectorFotoTrabajo.tomarFoto(),
      ).thenAnswer((_) async => _bytesFotoValidos);
      when(
        () => evidenciaRepositorio.capturarEvidencia(
          bytesOriginales: any(named: 'bytesOriginales'),
          tipo: any(named: 'tipo'),
          fecha: any(named: 'fecha'),
        ),
      ).thenAnswer((_) async => 'uuid-evidencia-campo-2');
      when(
        () => trabajoRepositorio.cerrarTrabajo(
          trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
          fin: any(named: 'fin'),
          litrosSobrante: any(named: 'litrosSobrante'),
          evidenciaImagenCampoUuidCliente: any(
            named: 'evidenciaImagenCampoUuidCliente',
          ),
        ),
      ).thenThrow(Exception('Error en base de datos'));

      await tester.tap(find.byKey(const Key('boton_cerrar_trabajo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_tomar_foto_campo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre_trabajo')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error al cerrar trabajo'), findsOneWidget);
    });
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
    await completarFormularioApertura(tester);

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
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await completarFormularioApertura(tester);

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
    ).thenAnswer((_) async => _sesionAbierta());

    final bloc = SesionBloc(
      sesionRepositorio: sesionRepositorio,
      personaOperativaStore: personaStore,
      trabajoUuidCliente: 'uuid-trabajo-1',
    );
    addTearDown(bloc.close);

    await bombear(tester, bloc);
    await completarFormularioApertura(tester);

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

  group('condiciones al abrir sesión (HU-06)', () {
    testWidgets('dentro de rango: el campo de observación no aparece', (
      tester,
    ) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('apertura_viento')), '10');
      await tester.enterText(
        find.byKey(const Key('apertura_temperatura')),
        '20',
      );
      await tester.enterText(find.byKey(const Key('apertura_humedad')), '50');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apertura_observacion')), findsNothing);
      expect(find.byKey(const Key('apertura_firma')), findsNothing);
    });

    testWidgets(
      'fuera de rango: el campo de observación aparece recién cuando el '
      'valor ingresado supera el umbral',
      (tester) async {
        when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);

        final bloc = SesionBloc(
          sesionRepositorio: sesionRepositorio,
          personaOperativaStore: personaStore,
          trabajoUuidCliente: 'uuid-trabajo-1',
        );
        addTearDown(bloc.close);

        await bombear(tester, bloc);
        await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('apertura_viento')), '10');
        await tester.enterText(
          find.byKey(const Key('apertura_temperatura')),
          '20',
        );
        await tester.enterText(find.byKey(const Key('apertura_humedad')), '50');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('apertura_observacion')), findsNothing);

        // Viento por encima del umbral (17 km/h): aparece observación/firma.
        await tester.enterText(find.byKey(const Key('apertura_viento')), '20');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('apertura_observacion')), findsOneWidget);
        expect(find.byKey(const Key('apertura_firma')), findsOneWidget);

        // Vuelve a estar dentro de rango: desaparece de nuevo.
        await tester.enterText(find.byKey(const Key('apertura_viento')), '10');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('apertura_observacion')), findsNothing);
        expect(find.byKey(const Key('apertura_firma')), findsNothing);
      },
    );

    testWidgets(
      'fuera de rango sin observación ni firma: la validación bloquea la '
      'confirmación sin llamar al repositorio',
      (tester) async {
        when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);

        final bloc = SesionBloc(
          sesionRepositorio: sesionRepositorio,
          personaOperativaStore: personaStore,
          trabajoUuidCliente: 'uuid-trabajo-1',
        );
        addTearDown(bloc.close);

        await bombear(tester, bloc);
        await completarFormularioApertura(
          tester,
          viento: '20',
          temperatura: '20',
          humedad: '50',
        );

        expect(find.text('La observación es obligatoria'), findsOneWidget);
        expect(find.text('La firma es obligatoria'), findsOneWidget);
        // El diálogo sigue abierto — nunca se dispachó el evento.
        expect(
          find.byKey(const Key('boton_confirmar_apertura')),
          findsOneWidget,
        );
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

    testWidgets(
      'fuera de rango con observación y firma: abre la sesión pasando '
      'ambas al repositorio',
      (tester) async {
        when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
            temperaturaC: Decimal.parse('20'),
            humedadPct: Decimal.parse('50'),
            observacionAgronomo: 'Viento fuerte, se autoriza',
            firmaObservacion: 'Ing. Agr. Juana Pérez',
          ),
        ).thenAnswer((_) async => _sesionAbierta());

        final bloc = SesionBloc(
          sesionRepositorio: sesionRepositorio,
          personaOperativaStore: personaStore,
          trabajoUuidCliente: 'uuid-trabajo-1',
        );
        addTearDown(bloc.close);

        await bombear(tester, bloc);
        await completarFormularioApertura(
          tester,
          viento: '20',
          temperatura: '20',
          humedad: '50',
          observacion: 'Viento fuerte, se autoriza',
          firma: 'Ing. Agr. Juana Pérez',
        );

        expect(find.text('Sesión activa'), findsOneWidget);
      },
    );
  });

  group('relevo de piloto al abrir sesión (HU-07)', () {
    testWidgets('el dropdown de auxiliar se puebla con los auxiliares del '
        'repositorio', (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
      when(() => sesionRepositorio.auxiliaresDisponibles()).thenAnswer(
        (_) async => const [
          Auxiliar(id: 1, nombre: 'Ana Auxiliar'),
          Auxiliar(id: 2, nombre: 'Beto Auxiliar'),
        ],
      );

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apertura_auxiliar')));
      await tester.pumpAndSettle();

      expect(find.text('Ana Auxiliar'), findsOneWidget);
      expect(find.text('Beto Auxiliar'), findsOneWidget);
    });

    testWidgets('pasa auxiliarId/dronId/hectareaInicialAcumulada exactos al '
        'repositorio', (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
      when(() => sesionRepositorio.auxiliaresDisponibles()).thenAnswer(
        (_) async => const [Auxiliar(id: 2, nombre: 'Beto Auxiliar')],
      );
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
          auxiliarId: 2,
          dronId: 9,
          hectareaInicialAcumulada: Decimal.parse('100.50'),
        ),
      ).thenAnswer((_) async => _sesionAbierta());

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await completarFormularioApertura(
        tester,
        auxiliarNombre: 'Beto Auxiliar',
        dronId: '9',
        hectareaInicialAcumulada: '100.50',
      );

      expect(find.text('Sesión activa'), findsOneWidget);
    });
  });

  group('cierre por acumulado (HU-07)', () {
    testWidgets('sesión con hectareaInicialAcumulada: muestra el campo de '
        'acumulado final en vez del de hectáreas directas', (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
          auxiliarId: any(named: 'auxiliarId'),
          dronId: any(named: 'dronId'),
          hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
        ),
      ).thenAnswer(
        (_) async =>
            _sesionAbierta(hectareaInicialAcumulada: Decimal.parse('100.50')),
      );

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await completarFormularioApertura(tester);

      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cierre_acumulado_final')), findsOneWidget);
      expect(find.byKey(const Key('cierre_hectareas')), findsNothing);
    });

    testWidgets('acumulado final menor al inicial: la validación bloquea la '
        'confirmación sin llamar al repositorio', (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
          auxiliarId: any(named: 'auxiliarId'),
          dronId: any(named: 'dronId'),
          hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
        ),
      ).thenAnswer(
        (_) async =>
            _sesionAbierta(hectareaInicialAcumulada: Decimal.parse('100.50')),
      );

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await completarFormularioApertura(tester);

      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cierre_acumulado_final')),
        '90',
      );
      await tester.tap(find.byKey(const Key('cierre_motivo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Relevo de piloto'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
      await tester.pumpAndSettle();

      expect(
        find.text('No puede ser menor al acumulado inicial (100.5)'),
        findsOneWidget,
      );
      verifyNever(
        () => sesionRepositorio.cerrarSesion(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          fin: any(named: 'fin'),
          motivoCierre: any(named: 'motivoCierre'),
          hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
          hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
          litrosConsumidos: any(named: 'litrosConsumidos'),
        ),
      );
    });

    testWidgets('acumulado final válido: pasa hectareaFinalAcumulada al '
        'repositorio y muestra la diferencia calculada', (tester) async {
      when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 1);
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
          auxiliarId: any(named: 'auxiliarId'),
          dronId: any(named: 'dronId'),
          hectareaInicialAcumulada: any(named: 'hectareaInicialAcumulada'),
        ),
      ).thenAnswer(
        (_) async =>
            _sesionAbierta(hectareaInicialAcumulada: Decimal.parse('100.50')),
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
        (_) async => _sesionCerrada(
          motivoCierre: 'relevo_piloto',
          hectareasDeclaradasCierre: Decimal.parse('20.25'),
        ),
      );

      final bloc = SesionBloc(
        sesionRepositorio: sesionRepositorio,
        personaOperativaStore: personaStore,
        trabajoUuidCliente: 'uuid-trabajo-1',
      );
      addTearDown(bloc.close);

      await bombear(tester, bloc);
      await completarFormularioApertura(tester);

      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cierre_acumulado_final')),
        '120.75',
      );
      await tester.tap(find.byKey(const Key('cierre_motivo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Relevo de piloto'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
      await tester.pumpAndSettle();

      expect(find.text('Sesión cerrada'), findsOneWidget);
      expect(find.text('Hectáreas declaradas (cierre): 20.25'), findsOneWidget);
    });
  });
}
