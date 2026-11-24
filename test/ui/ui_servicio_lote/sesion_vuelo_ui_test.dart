// UI de la sesión de vuelo en el lote (tarea 46): cada estado del bloc en
// los cuatro formatos, y el comportamiento de presentación que no depende
// del dominio — acciones ancladas de 56 px, estado de sync visible, la
// salida para retomar tras una pausa y el aviso de incidencias.

import 'package:agrocom_field/features/estado_sync/presentation/indicador_sync.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_cubit.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_estado.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/auxiliar.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_apertura.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_condiciones.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_estado.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_evento.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_vista.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_estado.dart';
import 'package:agrocom_field/nucleo/sync/estado_sync.dart';
import 'package:agrocom_field/nucleo/sync/sync_cubit.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'ayudas.dart';

class _SesionBlocFalso extends MockBloc<SesionEvento, SesionEstado>
    implements SesionBloc {}

class _TrabajoCubitFalso extends MockCubit<TrabajoEstado>
    implements TrabajoCubit {}

class _IncidenciaCubitFalso extends MockCubit<IncidenciaEstado>
    implements IncidenciaCubit {}

class _SyncCubitFalso extends MockCubit<EstadoMotorSync> implements SyncCubit {}

final _abierta = Sesion(
  uuidCliente: 'uuid-sesion-1',
  trabajoUuidCliente: 'uuid-trabajo-1',
  secuencia: 2,
  pilotoId: 1,
  hectareasDeclaradas: Decimal.parse('18.5'),
  inicio: DateTime(2026, 11, 23, 9, 30),
  estado: EstadoSesion.abierta,
);

Sesion _cerrada({String motivo = 'clima'}) => Sesion(
  uuidCliente: 'uuid-sesion-1',
  trabajoUuidCliente: 'uuid-trabajo-1',
  secuencia: 2,
  pilotoId: 1,
  hectareasDeclaradas: Decimal.parse('18.5'),
  inicio: DateTime(2026, 11, 23, 9, 30),
  estado: EstadoSesion.cerrada,
  fin: DateTime(2026, 11, 23, 11, 5),
  motivoCierre: motivo,
  hectareasDeclaradasCierre: Decimal.parse('24.75'),
  litrosConsumidos: Decimal.parse('36.5'),
  uuidClienteCierre: 'uuid-cierre-1',
);

final _trabajoCerrado = Trabajo(
  uuidCliente: 'uuid-trabajo-1',
  ordenId: 1,
  loteId: 3,
  nroAplicacion: 2,
  hectareasDeclaradas: Decimal.zero,
  inicio: DateTime(2026, 11, 23, 8),
  estado: EstadoTrabajo.cerrado,
);

Future<_SesionBlocFalso> _montar(
  WidgetTester tester,
  SesionEstado estado, {
  TrabajoEstado trabajo = const TrabajoInicial(),
  RestriccionApertura restriccion = RestriccionApertura.ninguna,
  SyncCubit? sync,
}) async {
  final bloc = _SesionBlocFalso();
  whenListen(bloc, const Stream<SesionEstado>.empty(), initialState: estado);
  when(() => bloc.trabajoUuidCliente).thenReturn('uuid-trabajo-1');
  when(bloc.restriccionApertura).thenAnswer((_) async => restriccion);
  when(
    bloc.limitesCondiciones,
  ).thenAnswer((_) async => LimitesCondiciones.porDefecto());
  when(bloc.auxiliaresDisponibles).thenAnswer((_) async => const <Auxiliar>[]);
  final trabajoCubit = _TrabajoCubitFalso();
  whenListen(
    trabajoCubit,
    const Stream<TrabajoEstado>.empty(),
    initialState: trabajo,
  );
  final incidenciaCubit = _IncidenciaCubitFalso();
  whenListen(
    incidenciaCubit,
    const Stream<IncidenciaEstado>.empty(),
    initialState: const IncidenciaInicial(),
  );

  Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AgrocomThemeCampo.construir(),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<SesionBloc>.value(value: bloc),
        BlocProvider<TrabajoCubit>.value(value: trabajoCubit),
      ],
      child: SesionVueloVista(crearIncidenciaCubit: (_) => incidenciaCubit),
    ),
  );
  if (sync != null) {
    app = BlocProvider<SyncCubit>.value(value: sync, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await cargarFuentes();
    registerFallbackValue(const SesionCargaSolicitada());
  });

  group('pantallas', () {
    variantesDePantalla('sesion_inicial', (tester) async {
      await _montar(tester, const SesionInicial());
    });

    variantesDePantalla('sesion_activa', (tester) async {
      await _montar(tester, SesionActiva(_abierta));
    });

    variantesDePantalla('sesion_cerrada_pausa', (tester) async {
      await _montar(tester, SesionCerrada(_cerrada()));
    });

    variantesDePantalla('sesion_trabajo_cerrado', (tester) async {
      await _montar(
        tester,
        SesionCerrada(_cerrada(motivo: 'completado')),
        trabajo: TrabajoCerrado(_trabajoCerrado),
      );
    });

    variantesDePantalla('sesion_error', (tester) async {
      await _montar(
        tester,
        const SesionError(
          'Tu usuario no tiene una persona operativa asignada — no se '
          'puede abrir sesión. Contactá a Agrocom.',
        ),
      );
    });

    variantesDePantalla('sesion_apertura_fuera_de_rango', (tester) async {
      await _montar(tester, const SesionInicial());
      await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('apertura_viento')), '25');
      await tester.enterText(
        find.byKey(const Key('apertura_temperatura')),
        '31',
      );
      await tester.enterText(find.byKey(const Key('apertura_humedad')), '40');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apertura_fuera_de_rango')), findsOneWidget);
    });

    variantesDePantalla('sesion_cierre', (tester) async {
      await _montar(tester, SesionActiva(_abierta));
      await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cierre_motivo')), findsOneWidget);
    });

    variantesDePantalla('sesion_cierre_trabajo', (tester) async {
      await _montar(tester, SesionCerrada(_cerrada()));
      await tester.tap(find.byKey(const Key('boton_cerrar_trabajo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('boton_tomar_foto_campo')), findsOneWidget);
    });

    variantesDePantalla('incidencia', (tester) async {
      final cubit = _IncidenciaCubitFalso();
      whenListen(
        cubit,
        const Stream<IncidenciaEstado>.empty(),
        initialState: const IncidenciaInicial(),
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AgrocomThemeCampo.construir(),
          home: BlocProvider<IncidenciaCubit>.value(
            value: cubit,
            child: const IncidenciaVista(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('acciones para guantes', () {
    testWidgets('en vuelo, las dos acciones miden al menos 56 px y quedan '
        'visibles sin scroll', (tester) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _montar(tester, SesionActiva(_abierta));

      for (final key in ['boton_reportar_incidencia', 'boton_cerrar_sesion']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.height, greaterThanOrEqualTo(56), reason: key);
        expect(rect.bottom, lessThanOrEqualTo(640), reason: key);
      }
      // La principal es la de más abajo: al alcance del pulgar.
      expect(
        tester.getRect(find.byKey(const Key('boton_cerrar_sesion'))).top,
        greaterThan(
          tester
              .getRect(find.byKey(const Key('boton_reportar_incidencia')))
              .bottom,
        ),
      );
    });

    testWidgets('con el texto al 200 % el botón crece en vez de cortar', (
      tester,
    ) async {
      prepararPantalla(tester, const Size(360, 640), 2);
      await _montar(tester, SesionActiva(_abierta));

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const Key('boton_reportar_incidencia')))
            .height,
        greaterThan(56),
      );
    });

    testWidgets('reportar incidencia abre la pantalla de incidencias', (
      tester,
    ) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _montar(tester, SesionActiva(_abierta));

      await tester.tap(find.byKey(const Key('boton_reportar_incidencia')));
      await tester.pumpAndSettle();

      expect(find.byType(IncidenciaVista), findsOneWidget);
      expect(find.byKey(const Key('incidencia_nota_guardado')), findsOneWidget);
    });
  });

  group('pausa y retomar', () {
    testWidgets('un cierre que no es «completado» ofrece abrir otra sesión, '
        'con cerrar trabajo como acción principal', (tester) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _montar(tester, SesionCerrada(_cerrada(motivo: 'fin_jornada')));

      expect(find.byKey(const Key('boton_abrir_otra_sesion')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('boton_cerrar_trabajo')),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('boton_abrir_otra_sesion')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apertura_viento')), findsOneWidget);
    });

    testWidgets('un cierre «completado» no ofrece otra sesión', (tester) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _montar(tester, SesionCerrada(_cerrada(motivo: 'completado')));

      expect(find.byKey(const Key('boton_abrir_otra_sesion')), findsNothing);
      expect(find.byKey(const Key('boton_cerrar_trabajo')), findsOneWidget);
    });

    testWidgets('con el trabajo cerrado no queda ninguna acción de vuelo', (
      tester,
    ) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      await _montar(
        tester,
        SesionCerrada(_cerrada()),
        trabajo: TrabajoCerrado(_trabajoCerrado),
      );

      expect(find.byKey(const Key('boton_abrir_otra_sesion')), findsNothing);
      expect(find.byKey(const Key('trabajo_cerrado')), findsOneWidget);
    });
  });

  group('estado de sincronización', () {
    Future<EstadoSyncVisibleCampo> visibleCon(
      WidgetTester tester,
      EstadoMotorSync? motor,
    ) async {
      prepararPantalla(tester, const Size(360, 640), 1);
      SyncCubit? sync;
      if (motor != null) {
        sync = _SyncCubitFalso();
        whenListen(
          sync,
          const Stream<EstadoMotorSync>.empty(),
          initialState: motor,
        );
      }
      await _montar(tester, SesionActiva(_abierta), sync: sync);
      return tester
          .widget<EstadoSyncCampo>(find.byKey(const Key('indicador_sync')))
          .estado;
    }

    testWidgets('sin motor de sync en el árbol: guardado en el dispositivo', (
      tester,
    ) async {
      expect(
        await visibleCon(tester, null),
        EstadoSyncVisibleCampo.guardadoLocal,
      );
      expect(find.byKey(const Key('sesion_nota_guardado')), findsOneWidget);
    });

    testWidgets('motor sincronizando: se ve «Sincronizando»', (tester) async {
      expect(
        await visibleCon(tester, EstadoMotorSync.sincronizando),
        EstadoSyncVisibleCampo.sincronizando,
      );
      expect(find.text('SINCRONIZANDO'), findsOneWidget);
    });

    testWidgets('motor con error: se ve «Sin sincronizar», con texto e '
        'ícono además del color', (tester) async {
      expect(
        await visibleCon(tester, EstadoMotorSync.error),
        EstadoSyncVisibleCampo.sinSincronizar,
      );
      expect(find.text('SIN SINCRONIZAR'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sincronización: Sin sincronizar'),
        findsOneWidget,
      );
    });

    test('un motor ocioso no se presenta como sincronizado', () {
      expect(
        IndicadorSync.visibleDe(EstadoMotorSync.ocioso),
        EstadoSyncVisibleCampo.guardadoLocal,
      );
    });
  });
}
