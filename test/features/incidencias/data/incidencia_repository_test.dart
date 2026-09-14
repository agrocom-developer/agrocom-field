// HU-08: `IncidenciaRepository` contra una base `drift` en memoria + un
// directorio temporal real para la evidencia (mismo patrón que
// `evidencia_repository_test.dart`) — precondición "sesión existente y
// abierta" sin escribir nada (ni incidencia, ni evidencia) si falla, y el
// payload EXACTO que viaja a `POST /api/sync`.

import 'dart:convert';
import 'dart:io';

import 'package:agrocom_field/features/incidencias/data/incidencia_repository.dart';
import 'package:agrocom_field/features/incidencias/domain/reglas_incidencia.dart';
import 'package:agrocom_field/features/incidencias/domain/tipo_incidencia.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/sesion_local.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CompresorFalso extends Mock implements CompresorEvidencia {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late AppDatabase db;
  late Directory directorioTemporal;
  late _CompresorFalso compresor;
  late EvidenciaRepository evidenciaRepositorio;
  late IncidenciaRepository incidenciaRepositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    directorioTemporal = Directory.systemTemp.createTempSync(
      'incidencias_test_',
    );
    compresor = _CompresorFalso();
    when(
      () => compresor.comprimir(any()),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    evidenciaRepositorio = EvidenciaRepository(
      db,
      compresor: compresor,
      directorioEvidencias: directorioTemporal,
    );
    incidenciaRepositorio = IncidenciaRepository(
      db,
      evidenciaRepository: evidenciaRepositorio,
    );
  });

  tearDown(() async {
    await db.close();
    if (directorioTemporal.existsSync()) {
      directorioTemporal.deleteSync(recursive: true);
    }
  });

  Future<void> sembrarSesion(
    String uuidCliente, {
    EstadoSesionLocal estado = EstadoSesionLocal.abierta,
  }) async {
    await db
        .into(db.trabajoLocal)
        .insert(
          TrabajoLocalCompanion.insert(
            uuidCliente: 'trabajo-$uuidCliente',
            ordenId: 1,
            loteId: 1,
            nroAplicacion: 1,
            inicio: DateTime.utc(2026, 9, 11, 8),
          ),
        );
    await db
        .into(db.sesionLocal)
        .insert(
          SesionLocalCompanion.insert(
            uuidCliente: uuidCliente,
            trabajoUuidCliente: 'trabajo-$uuidCliente',
            secuencia: 1,
            pilotoId: 7,
            inicio: DateTime.utc(2026, 9, 11, 9),
            estado: Value(estado),
          ),
        );
  }

  group('registrarIncidencia', () {
    test('sesión inexistente lanza SesionInexistenteExcepcion sin comprimir la '
        'foto ni escribir ninguna fila', () async {
      await expectLater(
        incidenciaRepositorio.registrarIncidencia(
          sesionUuidCliente: 'sesion-inexistente',
          tipo: TipoIncidencia.mecanica,
          hora: DateTime.utc(2026, 9, 11, 10),
          bytesFoto: Uint8List.fromList([9, 9, 9]),
        ),
        throwsA(isA<SesionInexistenteExcepcion>()),
      );

      verifyNever(() => compresor.comprimir(any()));
      expect(await db.select(db.incidenciaLocal).get(), isEmpty);
      expect(await db.select(db.evidenciaLocal).get(), isEmpty);
      expect(await db.select(db.colaSync).get(), isEmpty);
    });

    test('sesión cerrada lanza SesionCerradaExcepcion sin comprimir la foto ni '
        'escribir ninguna fila', () async {
      await sembrarSesion('sesion-cerrada', estado: EstadoSesionLocal.cerrada);

      await expectLater(
        incidenciaRepositorio.registrarIncidencia(
          sesionUuidCliente: 'sesion-cerrada',
          tipo: TipoIncidencia.clima,
          hora: DateTime.utc(2026, 9, 11, 10),
          bytesFoto: Uint8List.fromList([9, 9, 9]),
        ),
        throwsA(isA<SesionCerradaExcepcion>()),
      );

      verifyNever(() => compresor.comprimir(any()));
      expect(await db.select(db.incidenciaLocal).get(), isEmpty);
      expect(await db.select(db.evidenciaLocal).get(), isEmpty);
      expect(await db.select(db.colaSync).get(), isEmpty);
    });

    test('sesión abierta captura la evidencia, inserta IncidenciaLocal y '
        'encola incidencia en ColaSync con el payload exacto', () async {
      await sembrarSesion('sesion-abierta');
      final hora = DateTime.utc(2026, 9, 11, 10, 30);

      final incidencia = await incidenciaRepositorio.registrarIncidencia(
        sesionUuidCliente: 'sesion-abierta',
        tipo: TipoIncidencia.esc,
        descripcion: 'ESC trasero izquierdo caliente',
        hora: hora,
        bytesFoto: Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      expect(incidencia.sesionUuidCliente, 'sesion-abierta');
      expect(incidencia.tipo, TipoIncidencia.esc);
      expect(incidencia.descripcion, 'ESC trasero izquierdo caliente');
      expect(incidencia.evidenciaFotoUuidCliente, isNotEmpty);

      final filaEvidencia = (await db.select(db.evidenciaLocal).get()).single;
      expect(filaEvidencia.uuidCliente, incidencia.evidenciaFotoUuidCliente);
      expect(filaEvidencia.tipo, 'foto_incidencia');

      final filaIncidencia =
          await (db.select(db.incidenciaLocal)
                ..where((t) => t.uuidCliente.equals(incidencia.uuidCliente)))
              .getSingle();
      expect(filaIncidencia.sesionUuidCliente, 'sesion-abierta');
      expect(filaIncidencia.tipo, 'esc');
      expect(filaIncidencia.descripcion, 'ESC trasero izquierdo caliente');
      expect(
        filaIncidencia.evidenciaFotoUuidCliente,
        incidencia.evidenciaFotoUuidCliente,
      );

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('incidencia'))).getSingle();
      expect(filaOutbox.uuidCliente, incidencia.uuidCliente);

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload, {
        'sesion_uuid_cliente': 'sesion-abierta',
        'tipo_incidencia': 'esc',
        'descripcion': 'ESC trasero izquierdo caliente',
        'hora': hora.toUtc().toIso8601String(),
        'evidencia_foto_uuid_cliente': incidencia.evidenciaFotoUuidCliente,
      });
      // El campo se llama `tipo_incidencia`, nunca `tipo` a secas — esa
      // key ya distingue el tipo de registro del lote.
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);
    });

    test('descripción ausente encola descripcion en null', () async {
      await sembrarSesion('sesion-sin-descripcion');

      await incidenciaRepositorio.registrarIncidencia(
        sesionUuidCliente: 'sesion-sin-descripcion',
        tipo: TipoIncidencia.otro,
        hora: DateTime.utc(2026, 9, 11, 11),
        bytesFoto: Uint8List.fromList([1]),
      );

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('incidencia'))).getSingle();
      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload['descripcion'], isNull);
      expect(payload.containsKey('descripcion'), isTrue);

      final filaIncidencia = (await db.select(db.incidenciaLocal).get()).single;
      expect(filaIncidencia.descripcion, isNull);
    });
  });
}
