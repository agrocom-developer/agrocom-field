// Etapa 2 de HU-05 (esqueleto vertical: abrir trabajo -> abrir sesión ->
// cerrar sesión): `SesionRepository` contra una base `drift` en memoria
// (mismo patrón que `test/features/ordenes/data/ordenes_repository_test.dart`)
// — precondición "trabajo existente" sin escribir nada si falla, secuencia
// de sesión dentro del trabajo, secuencia global de `ColaSync` y el payload
// EXACTO de apertura/cierre que viaja a `POST /api/sync`.

import 'dart:convert';

import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_condiciones.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/sesion_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Condiciones climáticas dentro de rango por defecto (viento <= 17,
// temperatura <= 30, humedad <= 90) — usadas en los tests que no ejercitan
// específicamente HU-06, para no repetir el literal en cada llamado.
final _vientoDentroDeRango = Decimal.parse('10');
final _temperaturaDentroDeRango = Decimal.parse('20');
final _humedadDentroDeRango = Decimal.parse('50');

void main() {
  late AppDatabase db;
  late TrabajoRepository trabajoRepositorio;
  late SesionRepository sesionRepositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    trabajoRepositorio = TrabajoRepository(db);
    sesionRepositorio = SesionRepository(db);
  });

  tearDown(() => db.close());

  Future<String> abrirTrabajoDePrueba() async {
    final trabajo = await trabajoRepositorio.abrirTrabajo(
      ordenId: 1,
      loteId: 3,
      nroAplicacion: 1,
      inicio: DateTime.utc(2026, 9, 11, 10),
    );
    return trabajo.uuidCliente;
  }

  group('abrirSesion', () {
    test('sin trabajo previo, lanza TrabajoInexistenteExcepcion y no crea '
        'ninguna fila', () async {
      await expectLater(
        sesionRepositorio.abrirSesion(
          trabajoUuidCliente: 'inexistente',
          pilotoId: 7,
          inicio: DateTime.utc(2026, 9, 11, 10, 5),
          vientoKmh: _vientoDentroDeRango,
          temperaturaC: _temperaturaDentroDeRango,
          humedadPct: _humedadDentroDeRango,
        ),
        throwsA(isA<TrabajoInexistenteExcepcion>()),
      );

      expect(await db.select(db.sesionLocal).get(), isEmpty);
      expect(await db.select(db.colaSync).get(), isEmpty);
    });

    test('con trabajo existente crea SesionLocal y encola sesion en ColaSync '
        'con el payload exacto, incluidos los null explícitos', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();
      final inicio = DateTime.utc(2026, 9, 11, 10, 5);

      final sesion = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: inicio,
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );

      expect(sesion.estado, EstadoSesion.abierta);
      expect(sesion.secuencia, 1);

      final filaSesion = await (db.select(
        db.sesionLocal,
      )..where((t) => t.uuidCliente.equals(sesion.uuidCliente))).getSingle();
      expect(filaSesion.trabajoUuidCliente, trabajoUuidCliente);
      expect(filaSesion.secuencia, 1);
      expect(filaSesion.pilotoId, 7);
      expect(filaSesion.auxiliarId, isNull);
      expect(filaSesion.dronId, isNull);
      expect(filaSesion.hectareasDeclaradas, Decimal.parse('0'));
      expect(filaSesion.estado, EstadoSesionLocal.abierta);

      final filasOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('sesion'))).get();
      expect(filasOutbox, hasLength(1));
      final filaOutbox = filasOutbox.single;
      expect(filaOutbox.uuidCliente, sesion.uuidCliente);

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload, {
        'trabajo_uuid_cliente': trabajoUuidCliente,
        'secuencia': 1,
        'piloto_id': 7,
        'auxiliar_id': null,
        'dron_id': null,
        'hectareas_declaradas': '0',
        'hectarea_inicial_acumulada': null,
        'inicio': inicio.toUtc().toIso8601String(),
      });
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);
    });

    test('abrir dos sesiones sobre el mismo trabajo incrementa la secuencia de '
        'sesión (no confundir con la secuencia global de ColaSync)', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      final primera = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 9, 11, 10, 5),
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );
      final segunda = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 9, 11, 11, 5),
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );

      expect(primera.secuencia, 1);
      expect(segunda.secuencia, 2);

      final filaOutboxSegunda = await (db.select(
        db.colaSync,
      )..where((t) => t.uuidCliente.equals(segunda.uuidCliente))).getSingle();
      final payload =
          jsonDecode(filaOutboxSegunda.payload) as Map<String, dynamic>;
      expect(payload['secuencia'], 2);
    });
  });

  group('cerrarSesion', () {
    test('actualiza la fila con los campos de cierre sin pisar apertura, y '
        'encola cierre_sesion con el payload exacto', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();
      final sesionAbierta = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 9, 11, 10, 5),
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );
      final fin = DateTime.utc(2026, 9, 11, 11);

      final sesionCerrada = await sesionRepositorio.cerrarSesion(
        sesionUuidCliente: sesionAbierta.uuidCliente,
        fin: fin,
        motivoCierre: 'completado',
        hectareasDeclaradas: Decimal.parse('12.50'),
        litrosConsumidos: Decimal.parse('340.20'),
      );

      expect(sesionCerrada.estado, EstadoSesion.cerrada);
      // `drift` devuelve un `DateTime` local al leer (mismo instante, pero
      // `isUtc: false`) — normalizamos con `.toUtc()` antes de comparar,
      // porque `DateTime.==` sí distingue el flag `isUtc` aunque el instante
      // sea el mismo.
      expect(sesionCerrada.fin?.toUtc(), fin);
      expect(sesionCerrada.motivoCierre, 'completado');
      expect(sesionCerrada.hectareasDeclaradasCierre, Decimal.parse('12.50'));
      expect(sesionCerrada.litrosConsumidos, Decimal.parse('340.20'));
      expect(sesionCerrada.uuidClienteCierre, isNotNull);
      expect(sesionCerrada.uuidClienteCierre, isNot(sesionAbierta.uuidCliente));
      // Los campos de apertura no se pisan (invariante 6 de CLAUDE.md).
      expect(sesionCerrada.hectareasDeclaradas, Decimal.parse('0'));
      expect(sesionCerrada.inicio.toUtc(), sesionAbierta.inicio);
      expect(sesionCerrada.uuidCliente, sesionAbierta.uuidCliente);

      final filaSesion =
          await (db.select(db.sesionLocal)
                ..where((t) => t.uuidCliente.equals(sesionAbierta.uuidCliente)))
              .getSingle();
      expect(filaSesion.estado, EstadoSesionLocal.cerrada);
      expect(filaSesion.hectareasDeclaradas, Decimal.parse('0'));
      expect(filaSesion.inicio.toUtc(), sesionAbierta.inicio);

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('cierre_sesion'))).getSingle();
      expect(filaOutbox.uuidCliente, sesionCerrada.uuidClienteCierre);
      expect(filaOutbox.uuidCliente, isNot(sesionAbierta.uuidCliente));

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      // `Decimal.toString()` normaliza ceros finales ('12.50' -> '12.5',
      // '340.20' -> '340.2'), mismo valor numérico — se compara contra el
      // propio `.toString()`, no contra el literal de entrada.
      expect(payload, {
        'sesion_uuid_cliente': sesionAbierta.uuidCliente,
        'fin': fin.toUtc().toIso8601String(),
        'motivo_cierre': 'completado',
        'hectareas_declaradas': Decimal.parse('12.50').toString(),
        'litros_consumidos': Decimal.parse('340.20').toString(),
      });
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);
    });

    test('litrosConsumidos ausente encola litros_consumidos en null', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();
      final sesionAbierta = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 9, 11, 10, 5),
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );

      await sesionRepositorio.cerrarSesion(
        sesionUuidCliente: sesionAbierta.uuidCliente,
        fin: DateTime.utc(2026, 9, 11, 10, 10),
        motivoCierre: 'falla_equipo',
        hectareasDeclaradas: Decimal.parse('0'),
      );

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('cierre_sesion'))).getSingle();
      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload['litros_consumidos'], isNull);
      expect(payload.containsKey('litros_consumidos'), isTrue);
    });
  });

  test('ColaSync.secuencia queda estrictamente creciente entre trabajo, sesion '
      'y cierre_sesion sin importar el tipoEntidad', () async {
    final trabajo = await trabajoRepositorio.abrirTrabajo(
      ordenId: 1,
      loteId: 3,
      nroAplicacion: 1,
      inicio: DateTime.utc(2026, 9, 11, 10),
    );
    final sesion = await sesionRepositorio.abrirSesion(
      trabajoUuidCliente: trabajo.uuidCliente,
      pilotoId: 7,
      inicio: DateTime.utc(2026, 9, 11, 10, 5),
      vientoKmh: _vientoDentroDeRango,
      temperaturaC: _temperaturaDentroDeRango,
      humedadPct: _humedadDentroDeRango,
    );
    await sesionRepositorio.cerrarSesion(
      sesionUuidCliente: sesion.uuidCliente,
      fin: DateTime.utc(2026, 9, 11, 11),
      motivoCierre: 'completado',
      hectareasDeclaradas: Decimal.parse('12.50'),
    );

    final filas = await (db.select(
      db.colaSync,
    )..orderBy([(t) => OrderingTerm.asc(t.secuencia)])).get();

    expect(filas.map((f) => f.secuencia).toList(), [1, 2, 3, 4]);
    expect(filas.map((f) => f.tipoEntidad).toList(), [
      'trabajo',
      'sesion',
      'condiciones',
      'cierre_sesion',
    ]);
  });

  group('abrirSesion — condiciones (HU-06)', () {
    test('dentro de rango, sin observación ni firma, inserta igual las tres '
        'filas', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      final sesion = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: DateTime.utc(2026, 9, 11, 10, 5),
        vientoKmh: _vientoDentroDeRango,
        temperaturaC: _temperaturaDentroDeRango,
        humedadPct: _humedadDentroDeRango,
      );

      expect(await db.select(db.sesionLocal).get(), hasLength(1));
      final condicion = (await db.select(db.condicionLocal).get()).single;
      expect(condicion.sesionUuidCliente, sesion.uuidCliente);
      expect(condicion.momento, 'inicio_sesion');
      expect(condicion.vientoKmh, _vientoDentroDeRango);
      expect(condicion.temperaturaC, _temperaturaDentroDeRango);
      expect(condicion.humedadPct, _humedadDentroDeRango);
      expect(condicion.observacionAgronomo, isNull);
      expect(condicion.firmaObservacion, isNull);

      final filasOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('condiciones'))).get();
      expect(filasOutbox, hasLength(1));
    });

    test('fuera de rango sin observación ni firma lanza la excepción ANTES '
        'de escribir nada', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();

      await expectLater(
        sesionRepositorio.abrirSesion(
          trabajoUuidCliente: trabajoUuidCliente,
          pilotoId: 7,
          inicio: DateTime.utc(2026, 9, 11, 10, 5),
          vientoKmh: Decimal.parse('20'),
          temperaturaC: _temperaturaDentroDeRango,
          humedadPct: _humedadDentroDeRango,
        ),
        throwsA(isA<ObservacionAgronomoRequeridaExcepcion>()),
      );

      expect(await db.select(db.sesionLocal).get(), isEmpty);
      expect(await db.select(db.condicionLocal).get(), isEmpty);
      // `abrirTrabajoDePrueba` ya encoló su propia fila `trabajo` — la
      // precondición fallida no debe agregar ninguna fila `sesion` ni
      // `condiciones` encima de esa.
      expect(
        await (db.select(
          db.colaSync,
        )..where((t) => t.tipoEntidad.isNotValue('trabajo'))).get(),
        isEmpty,
      );
    });

    test('fuera de rango con observación y firma presentes inserta las tres '
        'filas correctas, con el payload de condiciones exacto contra el '
        'contrato', () async {
      final trabajoUuidCliente = await abrirTrabajoDePrueba();
      final inicio = DateTime.utc(2026, 9, 11, 10, 5);

      final sesion = await sesionRepositorio.abrirSesion(
        trabajoUuidCliente: trabajoUuidCliente,
        pilotoId: 7,
        inicio: inicio,
        vientoKmh: Decimal.parse('20'),
        temperaturaC: Decimal.parse('35'),
        humedadPct: Decimal.parse('95'),
        observacionAgronomo:
            'Viento y humedad por encima del umbral, se '
            'autoriza a rociar.',
        firmaObservacion: 'Ing. Agr. Juana Pérez',
      );

      expect(await db.select(db.sesionLocal).get(), hasLength(1));

      final condicion = (await db.select(db.condicionLocal).get()).single;
      expect(condicion.sesionUuidCliente, sesion.uuidCliente);
      expect(condicion.observacionAgronomo, isNotNull);
      expect(condicion.firmaObservacion, 'Ing. Agr. Juana Pérez');

      final filaOutbox = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('condiciones'))).getSingle();
      expect(filaOutbox.uuidCliente, condicion.uuidCliente);
      expect(filaOutbox.uuidCliente, isNot(sesion.uuidCliente));

      final payload = jsonDecode(filaOutbox.payload) as Map<String, dynamic>;
      expect(payload, {
        'sesion_uuid_cliente': sesion.uuidCliente,
        'momento': 'inicio_sesion',
        'viento_kmh': Decimal.parse('20').toString(),
        'temperatura_c': Decimal.parse('35').toString(),
        'humedad_pct': Decimal.parse('95').toString(),
        'observacion_agronomo':
            'Viento y humedad por encima del umbral, se '
            'autoriza a rociar.',
        'firma_observacion': 'Ing. Agr. Juana Pérez',
      });
      expect(payload.containsKey('tipo'), isFalse);
      expect(payload.containsKey('uuid_cliente'), isFalse);

      // La secuencia de `condiciones` va después de la de `sesion` — mismo
      // criterio que `cierre_sesion` después de `sesion` (invariante 5).
      final filaSesion = await (db.select(
        db.colaSync,
      )..where((t) => t.tipoEntidad.equals('sesion'))).getSingle();
      expect(filaOutbox.secuencia, greaterThan(filaSesion.secuencia));
    });
  });
}
