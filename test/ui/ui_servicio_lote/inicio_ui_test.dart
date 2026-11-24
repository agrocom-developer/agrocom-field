// UI de «Inicio» del piloto (tarea 46): sus servicios asignados, con lo que
// está en curso arriba, en los cuatro formatos.

import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_cubit.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_estado.dart';
import 'package:agrocom_field/features/inicio/presentation/inicio_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo_en_curso.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_estado.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/imagenes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

class _InicioCubitFalso extends MockCubit<InicioEstado>
    implements InicioCubit {}

class _TrabajoCubitFalso extends MockCubit<TrabajoEstado>
    implements TrabajoCubit {}

final _trabajo = TrabajoAsignado(
  id: 42,
  uuidCliente: '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a',
  ordenId: 1,
  loteId: 3,
  hectareasDeclaradas: Decimal.parse('42.5'),
  equipoTrabajoId: 7,
  updatedAt: DateTime.utc(2026, 9, 22),
  loteCodigo: 'L-14 · La Nena',
  nroAplicacion: 2,
  litrosHa: Decimal.parse('12'),
  cantidadLotesOrden: 2,
  vientoMaxKmh: Decimal.parse('17'),
  temperaturaMaxC: Decimal.parse('30'),
  humedadMinPct: Decimal.parse('40'),
  humedadMaxPct: Decimal.parse('90'),
  alturaVueloM: Decimal.parse('3'),
  velocidadVueloKmh: Decimal.parse('22'),
  anchoPasadaM: Decimal.parse('7.5'),
);

Future<void> _montar(WidgetTester tester, InicioEstado estado) async {
  final inicio = _InicioCubitFalso();
  whenListen(inicio, const Stream<InicioEstado>.empty(), initialState: estado);
  final trabajo = _TrabajoCubitFalso();
  whenListen(
    trabajo,
    const Stream<TrabajoEstado>.empty(),
    initialState: const TrabajoInicial(),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<InicioCubit>.value(value: inicio),
          BlocProvider<TrabajoCubit>.value(value: trabajo),
        ],
        child: InicioVista(
          crearTrabajoCubit: () => throw UnimplementedError(),
          crearSesionBloc: (_) => throw UnimplementedError(),
          crearIncidenciaCubit: (_) => throw UnimplementedError(),
          construirOrdenes: (_) => const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  await precargar(tester, ImagenesCampo.dronAgrasT50);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  variantesDePantalla('inicio_con_trabajo', (tester) async {
    await _montar(tester, InicioConTrabajo(_trabajo));
  });

  variantesDePantalla('inicio_en_curso', (tester) async {
    await _montar(
      tester,
      InicioConTrabajo(
        _trabajo,
        enCurso: TrabajoEnCurso(
          trabajoUuidCliente: _trabajo.uuidCliente,
          sesionUuidCliente: 'uuid-sesion-1',
          inicio: DateTime(2026, 11, 23, 9, 30),
          loteCodigo: 'L-14 · La Nena',
        ),
      ),
    );
  });

  variantesDePantalla('inicio_sin_trabajo', (tester) async {
    await _montar(tester, const InicioSinTrabajo());
  });

  testWidgets('titula la lista como servicios asignados y muestra el estado '
      'de sincronización', (tester) async {
    prepararPantalla(tester, const Size(360, 640), 1);
    await _montar(tester, InicioConTrabajo(_trabajo));

    expect(find.text('MIS SERVICIOS ASIGNADOS'), findsOneWidget);
    expect(find.byKey(const Key('indicador_sync')), findsOneWidget);
  });

  testWidgets('«Crear aplicación» mide al menos 56 px', (tester) async {
    prepararPantalla(tester, const Size(360, 640), 1);
    await _montar(tester, InicioConTrabajo(_trabajo));

    await tester.ensureVisible(find.byKey(const Key('boton_crear_aplicacion')));
    expect(
      tester.getSize(find.byKey(const Key('boton_crear_aplicacion'))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('con el texto al 200 % los datos se apilan en vez de cortarse', (
    tester,
  ) async {
    prepararPantalla(tester, const Size(360, 640), 2);
    await _montar(tester, InicioConTrabajo(_trabajo));
    expect(tester.takeException(), isNull);

    final hectareas = tester.getRect(find.byKey(const Key('inicio_hectareas')));
    final dosis = tester.getRect(find.byKey(const Key('inicio_dosis')));
    expect(dosis.top, greaterThanOrEqualTo(hectareas.bottom));
    expect(find.byType(GrupoStatsCampo), findsWidgets);
  });
}
