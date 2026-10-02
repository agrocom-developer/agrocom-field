// Tarea 28: un solo trabajo en curso por dispositivo, contra `drift` en
// memoria — `abrirTrabajo` y `abrirTrabajoAsignado` se niegan con
// `TrabajoEnCursoExcepcion` sin escribir ni encolar nada si hay una sesión
// abierta o un trabajo sin cerrar; volver al MISMO trabajo asignado no abre
// otro; y `TrabajoCubit` muestra el motivo.

import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_estado.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

void main() {
  late AppDatabase db;
  late TrabajoRepository repositorio;
  late SesionRepository sesionRepositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = TrabajoRepository(db);
    sesionRepositorio = SesionRepository(db);
  });

  tearDown(() => db.close());

  Future<String> abrirTrabajo({int ordenId = 1}) async =>
      (await repositorio.abrirTrabajo(
        ordenId: ordenId,
        loteId: 3,
        nroAplicacion: 1,
        inicio: DateTime.utc(2026, 10, 2, 9),
      )).uuidCliente;

  Future<String> abrirAsignado(String uuid) async =>
      (await repositorio.abrirTrabajoAsignado(
        uuidCliente: uuid,
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 2,
        inicio: DateTime.utc(2026, 10, 2, 9),
      )).uuidCliente;

  Future<String> abrirSesion(String trabajo) async =>
      (await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajo,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 10, 2, 9, 30),
        vientoKmh: Decimal.parse('10'),
        temperaturaC: Decimal.parse('20'),
        humedadPct: Decimal.parse('50'),
      )).uuidCliente;

  Future<void> cerrarTrabajo(String trabajo) => repositorio.cerrarTrabajo(
    trabajoUuidCliente: trabajo,
    fin: DateTime.utc(2026, 10, 2, 12),
    evidenciaImagenCampoUuidCliente: 'evidencia-campo-1',
  );

  /// Lo que hay en `drift` en las dos tablas que escribe una apertura.
  Future<(int, int)> filas() async => (
    (await db.select(db.trabajoLocal).get()).length,
    (await db.select(db.colaSync).get()).length,
  );

  group('abrirTrabajo', () {
    test('con un trabajo abierto sin sesión, rechaza sin escribir ni '
        'encolar nada', () async {
      await abrirTrabajo();
      final antes = await filas();

      await expectLater(
        abrirTrabajo(ordenId: 2),
        throwsA(
          isA<TrabajoEnCursoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            contains('Tenés un trabajo en curso'),
          ),
        ),
      );

      expect(await filas(), antes);
    });

    test(
      'con una sesión abierta, rechaza sin escribir ni encolar nada',
      () async {
        await abrirSesion(await abrirTrabajo());
        final antes = await filas();

        await expectLater(
          abrirTrabajo(ordenId: 2),
          throwsA(
            isA<TrabajoEnCursoExcepcion>().having(
              (e) => e.motivo,
              'motivo',
              contains('sesión en curso'),
            ),
          ),
        );

        expect(await filas(), antes);
      },
    );

    test('con el trabajo anterior ya cerrado, abre normalmente', () async {
      await cerrarTrabajo(await abrirTrabajo());

      await abrirTrabajo(ordenId: 2);

      expect((await filas()).$1, 2);
    });
  });

  group('abrirTrabajoAsignado', () {
    test('con otro trabajo en curso, rechaza sin escribir nada', () async {
      await abrirTrabajo();
      final antes = await filas();

      await expectLater(
        abrirAsignado('uuid-panel-42'),
        throwsA(isA<TrabajoEnCursoExcepcion>()),
      );

      expect(await filas(), antes);
    });

    test('volver al MISMO trabajo asignado en curso (con sesión abierta) no '
        'abre otro: devuelve ese, sin escribir ni encolar', () async {
      final uuid = await abrirAsignado('uuid-panel-42');
      await abrirSesion(uuid);
      final antes = await filas();

      final otraVez = await abrirAsignado('uuid-panel-42');

      expect(otraVez, 'uuid-panel-42');
      expect(await filas(), antes);
    });
  });

  test('TrabajoCubit: el rechazo llega a la pantalla con el motivo, no como '
      'un error genérico', () async {
    await abrirTrabajo();
    final cubit = TrabajoCubit(
      repositorio,
      evidenciaRepositorio: _EvidenciaRepositoryFalso(),
      selectorFoto: _SelectorFotoFalso(),
    );
    addTearDown(cubit.close);

    await cubit.abrirAsignado(
      uuidCliente: 'uuid-panel-42',
      ordenId: 1,
      loteId: 3,
      nroAplicacion: 2,
    );

    expect(
      cubit.state,
      const TrabajoError(
        'Tenés un trabajo en curso: volvé a él y cerralo antes de abrir '
        'otro trabajo.',
      ),
    );
  });
}
