// Etapa 2 de HU-05 (esqueleto vertical: abrir trabajo -> abrir sesión ->
// cerrar sesión): `TrabajoRepository` contra una base `drift` en memoria
// (mismo patrón que `test/features/ordenes/data/ordenes_repository_test.dart`)
// — invariante 3 de CLAUDE.md (insertar local + encolar en outbox, en una
// sola transacción) y el payload EXACTO que viaja a `POST /api/sync`.
//
// `cerrarTrabajo` (HU-09) se agrega en su propio `group`, más abajo.

import 'dart:convert';

import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/db/tablas/trabajo_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrabajoRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = TrabajoRepository(db);
  });

  tearDown(() => db.close());

  test(
    'abrirTrabajo crea la fila TrabajoLocal y encola trabajo en ColaSync',
    () async {
      final inicio = DateTime.utc(2026, 9, 11, 10);

      final trabajo = await repositorio.abrirTrabajo(
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 1,
        inicio: inicio,
      );

      final filaTrabajo = await (db.select(
        db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals(trabajo.uuidCliente))).getSingle();
      expect(filaTrabajo.ordenId, 1);
      expect(filaTrabajo.loteId, 3);
      expect(filaTrabajo.nroAplicacion, 1);
      expect(filaTrabajo.hectareasDeclaradas, Decimal.parse('0'));
      // `drift` devuelve un `DateTime` local al leer (mismo instante, pero
      // `isUtc: false`) — normalizamos con `.toUtc()` antes de comparar,
      // porque `DateTime.==` sí distingue el flag `isUtc` aunque el instante
      // sea el mismo.
      expect(filaTrabajo.inicio.toUtc(), inicio);

      final filasOutbox = await db.select(db.colaSync).get();
      expect(filasOutbox, hasLength(1));
      final filaOutbox = filasOutbox.single;
      expect(filaOutbox.uuidCliente, trabajo.uuidCliente);
      expect(filaOutbox.tipoEntidad, 'trabajo');
      expect(filaOutbox.secuencia, 1);
      expect(filaOutbox.estado, EstadoSync.pendiente);

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload, {
        'orden_id': 1,
        'lote_id': 3,
        'nro_aplicacion': 1,
        'hectareas_declaradas': '0',
        'inicio': inicio.toUtc().toIso8601String(),
      });
      // El payload nunca debe traer `tipo`/`uuid_cliente`: viajan por las
      // columnas dedicadas de `ColaSync` (ver `SyncEngine._registroDesdeFila`).
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);
    },
  );

  test('abrirTrabajo con hectareasDeclaradas explícitas las respeta en la fila '
      'y en el payload', () async {
    final trabajo = await repositorio.abrirTrabajo(
      ordenId: 2,
      loteId: 5,
      nroAplicacion: 2,
      hectareasDeclaradas: Decimal.parse('12.50'),
      inicio: DateTime.utc(2026, 9, 11, 10),
    );

    expect(trabajo.hectareasDeclaradas, Decimal.parse('12.50'));

    final filaOutbox = (await db.select(db.colaSync).get()).single;
    final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
    // `Decimal.toString()` normaliza ceros finales ('12.50' -> '12.5'),
    // mismo valor numérico — se compara contra el propio `.toString()`, no
    // contra el literal de entrada, para no acoplar el test a esa
    // normalización.
    expect(payload['hectareas_declaradas'], Decimal.parse('12.50').toString());
  });

  test('abrir dos trabajos en sucesión deja la secuencia global estrictamente '
      'creciente', () async {
    await repositorio.abrirTrabajo(
      ordenId: 1,
      loteId: 1,
      nroAplicacion: 1,
      inicio: DateTime.utc(2026, 9, 11, 10),
    );
    await repositorio.abrirTrabajo(
      ordenId: 2,
      loteId: 2,
      nroAplicacion: 1,
      inicio: DateTime.utc(2026, 9, 11, 10, 5),
    );

    final filas = await (db.select(
      db.colaSync,
    )..orderBy([(t) => OrderingTerm.asc(t.secuencia)])).get();
    expect(filas.map((f) => f.secuencia).toList(), [1, 2]);
  });

  group('cerrarTrabajo', () {
    Future<String> abrirTrabajoDePrueba() async {
      final trabajo = await repositorio.abrirTrabajo(
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 1,
        inicio: DateTime.utc(2026, 9, 11, 10),
      );
      return trabajo.uuidCliente;
    }

    test('sin evidenciaImagenCampoUuidCliente, lanza '
        'EvidenciaImagenCampoRequeridaExcepcion y no escribe nada', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      await expectLater(
        repositorio.cerrarTrabajo(
          trabajoUuidCliente: trabajoUuidCliente,
          fin: DateTime.utc(2026, 9, 11, 18),
          evidenciaImagenCampoUuidCliente: '',
        ),
        throwsA(isA<EvidenciaImagenCampoRequeridaExcepcion>()),
      );

      final fila = await (db.select(
        db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals(trabajoUuidCliente))).getSingle();
      expect(fila.estado, EstadoTrabajoLocal.abierto);
      expect(fila.fin, isNull);
      expect(fila.uuidClienteCierre, isNull);
      expect(
        await (db.select(
          db.colaSync,
        )..where((t) => t.tipoEntidad.equals('cierre_trabajo'))).get(),
        isEmpty,
      );
    });

    test('con evidenciaImagenCampoUuidCliente solo espacios, también rechaza '
        'ANTES de escribir', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      await expectLater(
        repositorio.cerrarTrabajo(
          trabajoUuidCliente: trabajoUuidCliente,
          fin: DateTime.utc(2026, 9, 11, 18),
          evidenciaImagenCampoUuidCliente: '   ',
        ),
        throwsA(isA<EvidenciaImagenCampoRequeridaExcepcion>()),
      );

      expect(await db.select(db.colaSync).get(), hasLength(1));
    });

    test('con evidencia, actualiza la fila con los campos de cierre sin pisar '
        'apertura, y encola cierre_trabajo con el payload exacto', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();
      final fin = DateTime.utc(2026, 9, 11, 18);

      final trabajoCerrado = await repositorio.cerrarTrabajo(
        trabajoUuidCliente: trabajoUuidCliente,
        fin: fin,
        litrosSobrante: Decimal.parse('5.25'),
        evidenciaImagenCampoUuidCliente: 'evidencia-1',
      );

      expect(trabajoCerrado.estado, EstadoTrabajo.cerrado);
      // `drift` devuelve un `DateTime` local al leer (mismo instante, pero
      // `isUtc: false`) — normalizamos con `.toUtc()` antes de comparar.
      expect(trabajoCerrado.fin?.toUtc(), fin);
      expect(trabajoCerrado.litrosSobrante, Decimal.parse('5.25'));
      expect(trabajoCerrado.evidenciaImagenCampoUuidCliente, 'evidencia-1');
      expect(trabajoCerrado.uuidClienteCierre, isNotNull);
      expect(trabajoCerrado.uuidClienteCierre, isNot(trabajoUuidCliente));
      // Los campos de apertura no se pisan (invariante 6 de CLAUDE.md).
      expect(trabajoCerrado.ordenId, 1);
      expect(trabajoCerrado.loteId, 3);
      expect(trabajoCerrado.nroAplicacion, 1);
      expect(trabajoCerrado.hectareasDeclaradas, Decimal.parse('0'));
      expect(trabajoCerrado.uuidCliente, trabajoUuidCliente);

      final filaTrabajo = await (db.select(
        db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals(trabajoUuidCliente))).getSingle();
      expect(filaTrabajo.estado, EstadoTrabajoLocal.cerrado);
      expect(filaTrabajo.hectareasDeclaradas, Decimal.parse('0'));

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('cierre_trabajo'))).getSingle();
      expect(filaOutbox.uuidCliente, trabajoCerrado.uuidClienteCierre);
      expect(filaOutbox.uuidCliente, isNot(trabajoUuidCliente));

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload, {
        'trabajo_uuid_cliente': trabajoUuidCliente,
        'fin': fin.toUtc().toIso8601String(),
        'litros_sobrante': Decimal.parse('5.25').toString(),
        'evidencia_imagen_campo_uuid_cliente': 'evidencia-1',
      });
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);
    });

    test('litrosSobrante ausente encola litros_sobrante en null', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      await repositorio.cerrarTrabajo(
        trabajoUuidCliente: trabajoUuidCliente,
        fin: DateTime.utc(2026, 9, 11, 18),
        evidenciaImagenCampoUuidCliente: 'evidencia-2',
      );

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('cierre_trabajo'))).getSingle();
      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload['litros_sobrante'], isNull);
    });
  });
}
