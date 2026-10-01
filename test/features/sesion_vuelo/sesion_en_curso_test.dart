// Tarea 27: volver a lo que quedó en curso, contra `drift` en memoria y con
// los repositorios reales — un `SesionBloc` NUEVO (el de una pantalla que se
// vuelve a abrir) arranca en la sesión que quedó abierta, con su mismo
// `uuid_cliente`, y la cierra sin crear otra; sin sesión abierta arranca en
// `SesionInicial` y el trabajo se cierra desde ahí.

import 'dart:convert';

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_apertura.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_estado.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_evento.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/sesion_local.dart';
import 'package:agrocom_field/nucleo/db/tablas/trabajo_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

void main() {
  late AppDatabase db;
  late TrabajoRepository trabajoRepositorio;
  late SesionRepository sesionRepositorio;
  late InicioRepository inicioRepositorio;
  late _PersonaOperativaStoreFalso personaStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    trabajoRepositorio = TrabajoRepository(db);
    sesionRepositorio = SesionRepository(db);
    inicioRepositorio = InicioRepository(db);
    personaStore = _PersonaOperativaStoreFalso();
    when(() => personaStore.leerPersonaId()).thenAnswer((_) async => 7);
  });

  tearDown(() => db.close());

  SesionBloc nuevoBloc(String trabajoUuidCliente) => SesionBloc(
    sesionRepositorio: sesionRepositorio,
    personaOperativaStore: personaStore,
    trabajoUuidCliente: trabajoUuidCliente,
  );

  Future<String> abrirTrabajo() async => (await trabajoRepositorio.abrirTrabajo(
    ordenId: 1,
    loteId: 3,
    nroAplicacion: 1,
    inicio: DateTime.utc(2026, 10, 1, 9),
  )).uuidCliente;

  Future<String> abrirSesion(String trabajoUuidCliente) async =>
      (await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 10, 1, 9, 30),
        vientoKmh: Decimal.parse('10'),
        temperaturaC: Decimal.parse('20'),
        humedadPct: Decimal.parse('50'),
      )).uuidCliente;

  /// Espera a que el Bloc procese la cola de eventos (FIFO, ver el
  /// transformer de `SesionBloc`).
  Future<void> procesar(SesionBloc bloc) =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('volver a una sesión abierta: un Bloc nuevo arranca en SesionActiva '
      'con ESA sesión y la cierra sin crear otra', () async {
    final trabajo = await abrirTrabajo();
    final sesionUuid = await abrirSesion(trabajo);
    final filasColaAntes = (await db.select(db.colaSync).get()).length;

    final bloc = nuevoBloc(trabajo)..add(const SesionCargaSolicitada());
    addTearDown(bloc.close);
    await procesar(bloc);

    final activa = bloc.state as SesionActiva;
    expect(activa.sesion.uuidCliente, sesionUuid);
    expect(activa.sesion.secuencia, 1);

    bloc.add(
      SesionCerrarSolicitada(
        motivoCierre: 'completado',
        hectareasDeclaradas: Decimal.parse('12.5'),
      ),
    );
    await procesar(bloc);

    expect(bloc.state, isA<SesionCerrada>());
    final sesiones = await db.select(db.sesionLocal).get();
    expect(sesiones, hasLength(1), reason: 'ninguna sesión nueva');
    expect(sesiones.single.uuidCliente, sesionUuid);
    expect(sesiones.single.estado, EstadoSesionLocal.cerrada);

    final cola = await db.select(db.colaSync).get();
    expect(cola, hasLength(filasColaAntes + 1), reason: 'solo el cierre');
    final cierre = cola.last;
    expect(cierre.tipoEntidad, 'cierre_sesion');
    expect(
      (jsonDecode(cierre.payload) as Map)['sesion_uuid_cliente'],
      sesionUuid,
    );

    // Con la sesión cerrada, «Inicio» pasa a mostrar el trabajo en curso.
    final enCurso = (await inicioRepositorio.enCurso().first)!;
    expect(enCurso.trabajoUuidCliente, trabajo);
    expect(enCurso.conSesion, isFalse);
  });

  test('volver a un trabajo abierto sin sesión: arranca en SesionInicial, '
      'sin escribir nada, y el trabajo se cierra desde ahí', () async {
    final trabajo = await abrirTrabajo();
    final sesionUuid = await abrirSesion(trabajo);
    await sesionRepositorio.cerrarSesion(
      sesionUuidCliente: sesionUuid,
      fin: DateTime.utc(2026, 10, 1, 10),
      motivoCierre: 'fin_jornada',
      hectareasDeclaradas: Decimal.parse('8'),
    );
    final colaAntes = (await db.select(db.colaSync).get()).length;

    final bloc = nuevoBloc(trabajo)..add(const SesionCargaSolicitada());
    addTearDown(bloc.close);
    await procesar(bloc);

    expect(bloc.state, const SesionInicial());
    expect(bloc.trabajoUuidCliente, trabajo);
    expect(await db.select(db.colaSync).get(), hasLength(colaAntes));

    await trabajoRepositorio.cerrarTrabajo(
      trabajoUuidCliente: bloc.trabajoUuidCliente,
      fin: DateTime.utc(2026, 10, 1, 11),
      evidenciaImagenCampoUuidCliente: 'evidencia-campo-1',
    );

    final fila = await db.select(db.trabajoLocal).getSingle();
    expect(fila.estado, EstadoTrabajoLocal.cerrado);
    expect(await inicioRepositorio.enCurso().first, isNull);
  });

  test('carga sin nada abierto: queda en SesionInicial', () async {
    final trabajo = await abrirTrabajo();

    final bloc = nuevoBloc(trabajo)..add(const SesionCargaSolicitada());
    addTearDown(bloc.close);
    await procesar(bloc);

    expect(bloc.state, const SesionInicial());
  });

  Future<void> sembrarOrden({String? motivoRetiro}) => db
      .into(db.ordenCatalogo)
      .insert(
        OrdenCatalogoCompanion.insert(
          id: const Value(1),
          contratoId: 1,
          loteId: 3,
          nroAplicacion: 1,
          fechaEmision: '2026-09-20',
          estado: 'vigente',
          updatedAt: DateTime.utc(2026, 9, 20),
          motivoRetiro: Value(motivoRetiro),
        ),
      );

  test('orden pausada con una sesión YA abierta: se retoma y se cierra '
      'igual', () async {
    final trabajo = await abrirTrabajo();
    final sesionUuid = await abrirSesion(trabajo);
    await sembrarOrden(motivoRetiro: 'pausada');

    final bloc = nuevoBloc(trabajo)..add(const SesionCargaSolicitada());
    addTearDown(bloc.close);
    await procesar(bloc);
    expect((bloc.state as SesionActiva).sesion.uuidCliente, sesionUuid);

    bloc.add(
      SesionCerrarSolicitada(
        motivoCierre: 'clima',
        hectareasDeclaradas: Decimal.parse('3'),
      ),
    );
    await procesar(bloc);

    expect(bloc.state, isA<SesionCerrada>());
    expect(
      (await db.select(db.sesionLocal).getSingle()).estado,
      EstadoSesionLocal.cerrada,
    );
  });

  group('restricción de apertura', () {
    test('orden pausada: bloquea una sesión nueva con el motivo; vigente '
        'otra vez, se puede', () async {
      final trabajo = await abrirTrabajo();
      await sembrarOrden(motivoRetiro: 'pausada');

      final pausada = await sesionRepositorio.restriccionAperturaDeTrabajo(
        trabajo,
      );
      expect(pausada.bloqueo, contains('orden de este trabajo está pausada'));

      await (db.update(db.ordenCatalogo)..where((t) => t.id.equals(1))).write(
        const OrdenCatalogoCompanion(motivoRetiro: Value(null)),
      );
      expect(
        await sesionRepositorio.restriccionAperturaDeTrabajo(trabajo),
        RestriccionApertura.ninguna,
      );
    });

    test('sin sesión abierta en el dispositivo, nada la impide', () async {
      final trabajo = await abrirTrabajo();

      expect(
        await sesionRepositorio.restriccionAperturaDeTrabajo(trabajo),
        RestriccionApertura.ninguna,
      );
    });

    test('con una sesión abierta en OTRO trabajo, bloquea con el motivo: '
        'nunca dos sesiones abiertas a la vez', () async {
      final primero = await abrirTrabajo();
      await abrirSesion(primero);
      final segundo = await abrirTrabajo();

      final restriccion = await sesionRepositorio.restriccionAperturaDeTrabajo(
        segundo,
      );

      expect(restriccion.bloqueada, isTrue);
      expect(restriccion.bloqueo, contains('Ya hay una sesión abierta'));
    });
  });
}
