// Etapa 4 de HU-05: widget test de `OrdenDetallePantalla` — botón "Abrir
// trabajo" visible solo en flavor piloto, navegación a sesión de vuelo,
// manejo de errores.

import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/features/ordenes/presentation/orden_detalle_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo_en_curso.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

// `SesionVueloPantalla` (HU-09) arma su propio `TrabajoCubit` nuevo, además
// del que `OrdenDetallePantalla` usa para abrir el trabajo — ninguno de los
// dos se ejercita más allá de la construcción en este archivo, que solo
// prueba `OrdenDetallePantalla`.
TrabajoCubit _crearTrabajoCubitDeSobra(TrabajoRepository repositorio) =>
    TrabajoCubit(
      repositorio,
      evidenciaRepositorio: _EvidenciaRepositoryFalso(),
      selectorFoto: _SelectorFotoFalso(),
    );

// Al abrir trabajo con éxito, `OrdenDetallePantalla` navega a
// `SesionVueloPantalla`, que sí invoca `crearSesionBloc` — a diferencia de
// lo que supone el resto de los tests de este archivo (que no llegan a
// completar la apertura), el camino feliz necesita una factory real, aunque
// sus dependencias nunca se ejerciten más allá de la construcción.
SesionBloc _crearSesionBlocDeSobra(String trabajoUuidCliente) => SesionBloc(
  sesionRepositorio: _SesionRepositoryFalso(),
  personaOperativaStore: _PersonaOperativaStoreFalso(),
  trabajoUuidCliente: trabajoUuidCliente,
);

// El botón es el último elemento del ListView, fuera del viewport de 600px
// del test por defecto: `find.byKey` ignora widgets "offstage" por default,
// así que este finder desactiva ese filtro (y `ensureVisible` lo scrollea a
// la vista antes de tocarlo, como haría un piloto real).
Finder _botonAbrirTrabajo() =>
    find.byKey(const Key('boton_abrir_trabajo'), skipOffstage: false);

OrdenVigente _orden({
  int id = 1,
  String? loteCodigo = 'L-01',
  Decimal? loteHectareas,
  int? cantidadLotes,
  Decimal? hectareasSolicitadas,
  Decimal? litrosHa,
  Decimal? kilosPorVuelo,
  bool sinDosis = false,
  bool sinTrabajoAsignado = false,
  String? observaciones = 'Test',
}) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: 1,
  nroAplicacion: 2,
  litrosHa: sinDosis || kilosPorVuelo != null
      ? litrosHa
      : (litrosHa ?? Decimal.parse('12.5')),
  kilosPorVuelo: kilosPorVuelo,
  // Tarea 23: los siete límites son los del trabajo asignado de la orden;
  // `sinTrabajoAsignado` reproduce lo que arma `OrdenesRepository` cuando
  // la orden no tiene ninguno.
  humedadMinPct: sinTrabajoAsignado ? null : Decimal.parse('60'),
  vientoMaxKmh: sinTrabajoAsignado ? null : Decimal.parse('15'),
  temperaturaMaxC: sinTrabajoAsignado ? null : Decimal.parse('32'),
  humedadMaxPct: sinTrabajoAsignado ? null : Decimal.parse('90'),
  alturaVueloM: sinTrabajoAsignado ? null : Decimal.parse('3'),
  velocidadVueloKmh: sinTrabajoAsignado ? null : Decimal.parse('18'),
  anchoPasadaM: sinTrabajoAsignado ? null : Decimal.parse('7'),
  observaciones: observaciones,
  emitidaPorContactoId: 2,
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
  cantidadLotes: cantidadLotes,
  hectareasSolicitadas: hectareasSolicitadas,
  loteCodigo: loteCodigo,
  loteHectareas: loteHectareas,
);

Trabajo _trabajo({
  String uuidCliente = 'uuid-trabajo-1',
  int ordenId = 1,
  int loteId = 1,
  int nroAplicacion = 2,
  Decimal? hectareasDeclaradas,
}) => Trabajo(
  uuidCliente: uuidCliente,
  ordenId: ordenId,
  loteId: loteId,
  nroAplicacion: nroAplicacion,
  hectareasDeclaradas: hectareasDeclaradas ?? Decimal.parse('0'),
  inicio: DateTime.utc(2026, 9, 11, 10, 0),
);

void main() {
  late _TrabajoRepositoryFalso trabajoRepositorio;

  setUp(() {
    trabajoRepositorio = _TrabajoRepositoryFalso();
    // Tarea 28: por defecto nada en curso — lo que ya suponían todos los
    // tests de «Abrir trabajo». Los de la tarea 28 lo re-stubean.
    when(
      () => trabajoRepositorio.enCurso(),
    ).thenAnswer((_) => Stream<TrabajoEnCurso?>.value(null));
  });

  testWidgets('flavor piloto: botón "Abrir trabajo" visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          // Fresco por invocación, igual que en producción
          // (`main_piloto.dart`): `BlocProvider(create: ...)` toma
          // posesión del cubit y lo cierra solo al desmontar — un
          // `addTearDown(cubit.close)` sobre la misma instancia duplica
          // el cierre y cuelga la finalización del test.
          crearTrabajoCubit: () =>
              _crearTrabajoCubitDeSobra(trabajoRepositorio),
          crearSesionBloc: (_) =>
              throw UnimplementedError('no se invoca en este test'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());

    expect(_botonAbrirTrabajo(), findsOneWidget);
  });

  testWidgets('flavor auxiliar: botón "Abrir trabajo" NO visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.auxiliar,
          crearTrabajoCubit: () =>
              _crearTrabajoCubitDeSobra(trabajoRepositorio),
          crearSesionBloc: (_) =>
              throw UnimplementedError('no se invoca en este test'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_botonAbrirTrabajo(), findsNothing);
  });

  testWidgets('flavor auxiliar: no invoca crearTrabajoCubit ni crearSesionBloc '
      '(factories que lanzan, como main_auxiliar.dart real)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.auxiliar,
          // Idénticas a las de `main_auxiliar.dart`: si la pantalla llegara
          // a invocarlas (regresión de HU-04), este test explota igual que
          // la app real lo haría.
          crearTrabajoCubit: () => throw UnimplementedError(
            'El flavor auxiliar no dispone de trabajo/sesión',
          ),
          crearSesionBloc: (_) => throw UnimplementedError(
            'El flavor auxiliar no dispone de trabajo/sesión',
          ),
          crearIncidenciaCubit: (_) => throw UnimplementedError(
            'El flavor auxiliar no dispone de trabajo/sesión',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Orden N.º 1'), findsOneWidget);
    expect(_botonAbrirTrabajo(), findsNothing);
  });

  testWidgets('tap al botón: muestra carga', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _trabajo();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () =>
              _crearTrabajoCubitDeSobra(trabajoRepositorio),
          // Camino feliz: la apertura exitosa navega a SesionVueloPantalla,
          // que sí construye un SesionBloc.
          crearSesionBloc: _crearSesionBlocDeSobra,
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    await tester.tap(_botonAbrirTrabajo());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // En éxito, navega; el spinner desaparece
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error al abrir trabajo: muestra SnackBar', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenThrow(Exception('Error simulado'));

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () =>
              _crearTrabajoCubitDeSobra(trabajoRepositorio),
          crearSesionBloc: (_) =>
              throw UnimplementedError('no se invoca en este test'),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    await tester.tap(_botonAbrirTrabajo());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Error al abrir trabajo'), findsOneWidget);
  });

  testWidgets('botón deshabilitado mientras carga', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _trabajo();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrdenDetallePantalla(
          orden: _orden(),
          flavor: Flavor.piloto,
          crearTrabajoCubit: () =>
              _crearTrabajoCubitDeSobra(trabajoRepositorio),
          // Camino feliz (tras el segundo transcurrido): navega a
          // SesionVueloPantalla, que sí construye un SesionBloc.
          crearSesionBloc: _crearSesionBlocDeSobra,
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boton = _botonAbrirTrabajo();
    // `BotonPrimarioCampo` (modo campo, ADR 0008) envuelve el botón de
    // Material que se habilita o no: el criterio se verifica sobre ese.
    final botonMaterial = find.descendant(
      of: boton,
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(botonMaterial).onPressed, isNotNull);

    await tester.tap(boton);
    await tester.pump();

    // Mientras carga, el botón está deshabilitado (onPressed == null)
    expect(tester.widget<FilledButton>(botonMaterial).onPressed, isNull);

    // Drena el Future retrasado de 1s pendiente: dejarlo sin resolver deja
    // un Timer vivo que `flutter_test` rechaza al finalizar el test.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  Future<void> bombearAuxiliar(WidgetTester tester, OrdenVigente orden) =>
      tester.pumpWidget(
        MaterialApp(
          home: OrdenDetallePantalla(
            orden: orden,
            flavor: Flavor.auxiliar,
            crearTrabajoCubit: () =>
                throw UnimplementedError('no se invoca en este test'),
            crearSesionBloc: (_) =>
                throw UnimplementedError('no se invoca en este test'),
            crearIncidenciaCubit: (_) =>
                throw UnimplementedError('no se invoca en este test'),
          ),
        ),
      );

  StatChipCampo chip(WidgetTester tester, String key) =>
      tester.widget<StatChipCampo>(find.byKey(Key(key), skipOffstage: false));

  testWidgets('TE-23: orden de varios lotes muestra las hectáreas de la '
      'orden entera y avisa cuántos lotes más cubre, no las del primer lote '
      'como si fueran las de la orden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bombearAuxiliar(
      tester,
      _orden(
        loteHectareas: Decimal.parse('120.5'),
        cantidadLotes: 3,
        hectareasSolicitadas: Decimal.parse('300.5'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('orden_lote_codigo'))).data,
      'L-01',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('orden_otros_lotes'))).data,
      'y 2 lotes más de la orden',
    );
    expect(chip(tester, 'orden_hectareas').valor, '300.5');
  });

  testWidgets('TE-23: orden de un solo lote no agrega el aviso de otros '
      'lotes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bombearAuxiliar(
      tester,
      _orden(
        loteHectareas: Decimal.parse('120.5'),
        cantidadLotes: 1,
        hectareasSolicitadas: Decimal.parse('120.5'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('orden_otros_lotes')), findsNothing);
    expect(chip(tester, 'orden_hectareas').valor, '120.5');
  });

  testWidgets('modo campo con datos: se construye bajo el tema campo, sin '
      'widgets de Material de ADR 0003, y muestra la orden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bombearAuxiliar(tester, _orden(loteHectareas: Decimal.parse('42.5')));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byKey(const Key('orden_lote_codigo')));
    expect(Theme.of(contexto).extension<TemaCampo>(), isNotNull);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(ListTile), findsNothing);

    expect(
      tester.widget<BadgeEstadoCampo>(find.byKey(const Key('orden_estado'))),
      isA<BadgeEstadoCampo>()
          .having((b) => b.texto, 'texto', 'vigente')
          .having((b) => b.estado, 'estado', EstadoBadgeCampo.ok),
    );
    expect(chip(tester, 'orden_hectareas').valor, '42.5');
    expect(chip(tester, 'orden_viento_max').valor, '15');
    expect(chip(tester, 'orden_temperatura_max').valor, '32');
    expect(chip(tester, 'orden_humedad_max').valor, '90');
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('dosis: con litros_ha muestra solo L/ha, nunca kg/vuelo', (
    tester,
  ) async {
    await bombearAuxiliar(tester, _orden(litrosHa: Decimal.parse('12.5')));
    await tester.pumpAndSettle();

    final dosis = chip(tester, 'orden_dosis');
    expect((dosis.valor, dosis.unidad), ('12.5', 'L/ha'));
    expect(find.textContaining('kg/vuelo', skipOffstage: false), findsNothing);
  });

  testWidgets('dosis: con kilos_por_vuelo muestra solo kg/vuelo, nunca L/ha', (
    tester,
  ) async {
    await bombearAuxiliar(tester, _orden(kilosPorVuelo: Decimal.parse('8')));
    await tester.pumpAndSettle();

    final dosis = chip(tester, 'orden_dosis');
    expect((dosis.valor, dosis.unidad), ('8', 'kg/vuelo'));
    expect(find.textContaining('L/ha', skipOffstage: false), findsNothing);
  });

  testWidgets('nulos: lote, hectáreas, dosis y observaciones se leen '
      '"sin datos", sin unidad ni dato inventado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bombearAuxiliar(
      tester,
      _orden(loteCodigo: null, sinDosis: true, observaciones: null),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('orden_lote_codigo'))).data,
      'sin datos',
    );
    for (final key in ['orden_hectareas', 'orden_dosis']) {
      final c = chip(tester, key);
      expect((c.valor, c.unidad), ('sin datos', null), reason: key);
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('orden_observaciones'))).data,
      'sin datos',
    );
    expect(find.textContaining('L/ha'), findsNothing);
    expect(find.textContaining('kg/vuelo'), findsNothing);
  });

  group('tarea 23: límites del trabajo asignado', () {
    FilaDatoCampo fila(WidgetTester tester, String etiqueta) =>
        tester.widget<FilaDatoCampo>(
          find.byWidgetPredicate(
            (w) => w is FilaDatoCampo && w.etiqueta == etiqueta,
            skipOffstage: false,
          ),
        );

    testWidgets('con trabajo asignado: límites climáticos y parámetros de '
        'vuelo con su unidad', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await bombearAuxiliar(tester, _orden());
      await tester.pumpAndSettle();

      final viento = chip(tester, 'orden_viento_max');
      expect((viento.valor, viento.unidad), ('15', 'km/h'));
      final temperatura = chip(tester, 'orden_temperatura_max');
      expect((temperatura.valor, temperatura.unidad), ('32', '°C'));
      final humedadMin = chip(tester, 'orden_humedad_min');
      expect((humedadMin.valor, humedadMin.unidad), ('60', '%'));
      final humedadMax = chip(tester, 'orden_humedad_max');
      expect((humedadMax.valor, humedadMax.unidad), ('90', '%'));
      final altura = fila(tester, 'Altura de vuelo');
      expect((altura.valor, altura.unidad), ('3', 'm'));
      final velocidad = fila(tester, 'Velocidad de vuelo');
      expect((velocidad.valor, velocidad.unidad), ('18', 'km/h'));
      final ancho = fila(tester, 'Ancho de pasada');
      expect((ancho.valor, ancho.unidad), ('7', 'm'));
    });

    testWidgets('sin trabajo asignado: cada límite se lee «sin datos», sin '
        'unidad ni valor inventado', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await bombearAuxiliar(tester, _orden(sinTrabajoAsignado: true));
      await tester.pumpAndSettle();

      for (final key in [
        'orden_viento_max',
        'orden_temperatura_max',
        'orden_humedad_min',
        'orden_humedad_max',
      ]) {
        final limite = chip(tester, key);
        expect((limite.valor, limite.unidad), ('sin datos', null), reason: key);
      }
      for (final etiqueta in [
        'Altura de vuelo',
        'Velocidad de vuelo',
        'Ancho de pasada',
      ]) {
        final limite = fila(tester, etiqueta);
        expect(
          (limite.valor, limite.unidad),
          ('sin datos', null),
          reason: etiqueta,
        );
      }
    });
  });

  testWidgets('tarea 25: el detalle ya no muestra «Velocidad máxima», que '
      'no existe en la orden de trabajo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bombearAuxiliar(tester, _orden());
    await tester.pumpAndSettle();

    expect(find.text('Velocidad máxima', skipOffstage: false), findsNothing);
    expect(find.text('Altura de vuelo', skipOffstage: false), findsOneWidget);
  });
}
