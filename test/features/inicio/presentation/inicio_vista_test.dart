// HU-70: widget test de «Inicio» del piloto — trabajo asignado con lote,
// hectáreas y una sola dosis (L/ha o kg/vuelo, nunca ambas), estado vacío
// explícito, «Crear aplicación» abriendo la sesión sobre el uuid_cliente
// del panel, y la barra con solo Inicio y Órdenes.

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_cubit.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
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

const _uuidPanel = '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a';

TrabajoAsignado _trabajo({
  String? loteCodigo = 'L-14',
  int? nroAplicacion = 2,
  Decimal? litrosHa,
  Decimal? kilosPorVuelo,
  int? cantidadLotesOrden = 2,
  String? limite,
}) => TrabajoAsignado(
  id: 42,
  uuidCliente: _uuidPanel,
  ordenId: 1,
  loteId: 3,
  hectareasDeclaradas: Decimal.parse('42.5'),
  equipoTrabajoId: 7,
  updatedAt: DateTime.utc(2026, 9, 22),
  loteCodigo: loteCodigo,
  nroAplicacion: nroAplicacion,
  litrosHa: litrosHa,
  kilosPorVuelo: kilosPorVuelo,
  cantidadLotesOrden: cantidadLotesOrden,
  humedadMinPct: limite == null ? null : Decimal.parse(limite),
  vientoMaxKmh: limite == null ? null : Decimal.parse(limite),
  temperaturaMaxC: limite == null ? null : Decimal.parse(limite),
  humedadMaxPct: limite == null ? null : Decimal.parse(limite),
  alturaVueloM: limite == null ? null : Decimal.parse(limite),
  velocidadVueloKmh: limite == null ? null : Decimal.parse(limite),
  anchoPasadaM: limite == null ? null : Decimal.parse(limite),
);

void main() {
  late _InicioRepositoryFalso inicioRepositorio;
  late _TrabajoRepositoryFalso trabajoRepositorio;
  late List<String> sesionesPedidas;

  setUpAll(() => registerFallbackValue(DateTime.utc(2026)));

  setUp(() {
    inicioRepositorio = _InicioRepositoryFalso();
    trabajoRepositorio = _TrabajoRepositoryFalso();
    sesionesPedidas = [];
  });

  Future<void> bombear(WidgetTester tester, TrabajoAsignado? trabajo) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(
      () => inicioRepositorio.trabajoAsignado(),
    ).thenAnswer((_) => Stream.value(trabajo));
    // Tarea 27: por defecto nada en curso en el dispositivo.
    when(
      () => inicioRepositorio.enCurso(),
    ).thenAnswer((_) => Stream.value(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AgrocomThemeCampo.construir(),
        home: InicioPantalla(
          crearCubit: () => InicioCubit(inicioRepositorio),
          crearTrabajoCubit: () => TrabajoCubit(
            trabajoRepositorio,
            evidenciaRepositorio: _EvidenciaRepositoryFalso(),
            selectorFoto: _SelectorFotoFalso(),
          ),
          crearSesionBloc: (trabajoUuidCliente) {
            sesionesPedidas.add(trabajoUuidCliente);
            // Tarea 27: la pantalla de sesión arranca leyendo la sesión
            // abierta del trabajo; acá no hay ninguna.
            final sesionRepositorio = _SesionRepositoryFalso();
            when(
              () => sesionRepositorio.sesionAbiertaDeTrabajo(any()),
            ).thenAnswer((_) async => null);
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

  StatChipCampo chip(WidgetTester tester, String key) =>
      tester.widget<StatChipCampo>(find.byKey(Key(key)));

  String? texto(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data;

  testWidgets('con trabajo asignado e insumo líquido: lote, hectáreas del '
      'equipo y L/ha, nunca kg/vuelo', (tester) async {
    await bombear(tester, _trabajo(litrosHa: Decimal.parse('12')));

    expect(find.byKey(const Key('inicio_sin_trabajo')), findsNothing);
    expect(texto(tester, 'inicio_lote'), 'L-14');
    expect(texto(tester, 'inicio_orden'), 'Orden N.º 1 · Aplicación N.º 2');
    expect(chip(tester, 'inicio_hectareas').valor, '42.5');
    expect(chip(tester, 'inicio_hectareas').unidad, 'ha');
    expect(chip(tester, 'inicio_dosis').valor, '12');
    expect(chip(tester, 'inicio_dosis').unidad, 'L/ha');
    expect(chip(tester, 'inicio_lotes_orden').valor, '2');
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('insumo sólido: kg/vuelo, nunca L/ha', (tester) async {
    await bombear(tester, _trabajo(kilosPorVuelo: Decimal.parse('8.5')));

    expect(chip(tester, 'inicio_dosis').valor, '8.5');
    expect(chip(tester, 'inicio_dosis').unidad, 'kg/vuelo');
    expect(find.textContaining('L / ha'), findsNothing);
    expect(find.textContaining('L/ha'), findsNothing);
  });

  testWidgets('sin trabajo asignado: estado vacío explícito, sin datos '
      'inventados', (tester) async {
    await bombear(tester, null);

    expect(find.byKey(const Key('inicio_sin_trabajo')), findsOneWidget);
    expect(find.text('Todavía no tenés un trabajo asignado'), findsOneWidget);
    expect(find.byKey(const Key('inicio_trabajo_asignado')), findsNothing);
    expect(find.byType(StatChipCampo), findsNothing);
    expect(find.byKey(const Key('boton_crear_aplicacion')), findsNothing);
  });

  testWidgets('orden o lote todavía no bajados: «sin datos» y «Crear '
      'aplicación» deshabilitado con su motivo', (tester) async {
    await bombear(
      tester,
      _trabajo(loteCodigo: null, nroAplicacion: null, cantidadLotesOrden: null),
    );

    expect(texto(tester, 'inicio_lote'), 'Lote sin datos');
    expect(chip(tester, 'inicio_dosis').valor, 'sin datos');
    expect(chip(tester, 'inicio_lotes_orden').valor, 'sin datos');
    expect(
      tester
          .widget<BotonPrimarioCampo>(
            find.byKey(const Key('boton_crear_aplicacion')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('inicio_falta_orden')), findsOneWidget);
  });

  testWidgets('«Crear aplicación» abre la sesión sobre el uuid_cliente del '
      'panel, sin abrir un trabajo nuevo', (tester) async {
    when(
      () => trabajoRepositorio.abrirTrabajoAsignado(
        uuidCliente: _uuidPanel,
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 2,
        inicio: any(named: 'inicio'),
      ),
    ).thenAnswer(
      (_) async => Trabajo(
        uuidCliente: _uuidPanel,
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 2,
        hectareasDeclaradas: Decimal.zero,
        inicio: DateTime.utc(2026, 9, 23, 8),
      ),
    );
    await bombear(tester, _trabajo(litrosHa: Decimal.parse('12')));

    await tester.tap(find.byKey(const Key('boton_crear_aplicacion')));
    await tester.pumpAndSettle();

    expect(find.byType(SesionVueloPantalla), findsOneWidget);
    expect(sesionesPedidas, [_uuidPanel]);
    verifyNever(
      () => trabajoRepositorio.abrirTrabajo(
        ordenId: any(named: 'ordenId'),
        loteId: any(named: 'loteId'),
        nroAplicacion: any(named: 'nroAplicacion'),
        inicio: any(named: 'inicio'),
      ),
    );
  });

  testWidgets('la barra lleva solo Inicio y Órdenes; Órdenes navega a la '
      'lista', (tester) async {
    await bombear(tester, null);

    final barra = tester.widget<BarraNavegacionCampo>(
      find.byType(BarraNavegacionCampo),
    );
    expect(barra.items.map((i) => i.etiqueta), ['Inicio', 'Órdenes']);
    expect(barra.items.every((i) => i.insignia == null), isTrue);

    await tester.tap(find.text('Órdenes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pantalla_ordenes_falsa')), findsOneWidget);
  });

  group('tarea 23: límites del trabajo asignado', () {
    const unidades = {
      'inicio_viento_max': 'km/h',
      'inicio_temperatura_max': '°C',
      'inicio_humedad_min': '%',
      'inicio_humedad_max': '%',
      'inicio_altura_vuelo': 'm',
      'inicio_velocidad_vuelo': 'km/h',
      'inicio_ancho_pasada': 'm',
    };

    testWidgets('con límites cargados: los muestra con su unidad', (
      tester,
    ) async {
      await bombear(tester, _trabajo(limite: '17.5'));

      expect(find.byKey(const Key('inicio_limites')), findsOneWidget);
      for (final MapEntry(:key, value: unidad) in unidades.entries) {
        final limite = chip(tester, key);
        expect((limite.valor, limite.unidad), ('17.5', unidad), reason: key);
      }
    });

    testWidgets('sin límites cargados: «sin datos», sin unidad ni valor '
        'inventado', (tester) async {
      await bombear(tester, _trabajo());

      for (final key in unidades.keys) {
        final limite = chip(tester, key);
        expect((limite.valor, limite.unidad), ('sin datos', null), reason: key);
      }
    });

    testWidgets('sin trabajo asignado no hay tarjeta de límites', (
      tester,
    ) async {
      await bombear(tester, null);

      expect(find.byKey(const Key('inicio_sin_trabajo')), findsOneWidget);
      expect(find.byKey(const Key('inicio_limites')), findsNothing);
    });
  });
}
