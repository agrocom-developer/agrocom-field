// Prueba de la migración de esquema v13 -> v14 (tarea 26): agrega a
// `orden_catalogo` y `trabajo_catalogo` la marca de retiro
// (`ordenes_retiradas`/`trabajos_retirados` de `agrocom-api` #313) y a
// `cursor_catalogo` el barrido completo en curso, con `ALTER TABLE`, sin
// perder ninguna fila, y resetea el cursor para forzar un barrido completo.
//
// Mismo patrón que `migracion_limpia_orden_test.dart` (v12 -> v13): esquema
// v13 completo escrito a mano con SQL crudo, `PRAGMA user_version = 13`, y
// recién ahí [AppDatabase] con el `schemaVersion` real.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v13 real: `orden_catalogo` ya sin clima/vuelo
/// y sin marca de retiro; `trabajo_catalogo` con los siete límites al final;
/// `cursor_catalogo` sin barrido.
const _createEsquemaV13 = '''
CREATE TABLE cola_sync (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  uuid_cliente TEXT NOT NULL UNIQUE,
  tipo_entidad TEXT NOT NULL,
  payload TEXT NOT NULL,
  secuencia INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  motivo_rechazo TEXT NULL,
  creado_en INTEGER NOT NULL
);

CREATE TABLE orden_catalogo (
  id INTEGER NOT NULL PRIMARY KEY,
  contrato_id INTEGER NOT NULL,
  lote_id INTEGER NOT NULL,
  cantidad_lotes INTEGER NULL,
  hectareas_solicitadas TEXT NULL,
  nro_aplicacion INTEGER NOT NULL,
  litros_ha TEXT NULL,
  kilos_por_vuelo TEXT NULL,
  observaciones TEXT NULL,
  emitida_por_contacto_id INTEGER NULL,
  fecha_emision TEXT NOT NULL,
  estado TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE lote_catalogo (
  id INTEGER NOT NULL PRIMARY KEY,
  propiedad_id INTEGER NOT NULL,
  codigo TEXT NOT NULL,
  hectareas TEXT NOT NULL,
  geometria TEXT NULL,
  restricciones TEXT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE persona_catalogo (
  id INTEGER NOT NULL PRIMARY KEY,
  nombre TEXT NOT NULL,
  rol TEXT NOT NULL,
  base_id INTEGER NULL,
  activo INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE cursor_catalogo (
  id INTEGER NOT NULL DEFAULT 0 PRIMARY KEY,
  cursor TEXT NULL
);

CREATE TABLE trabajo_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  orden_id INTEGER NOT NULL,
  lote_id INTEGER NOT NULL,
  nro_aplicacion INTEGER NOT NULL,
  hectareas_declaradas TEXT NOT NULL DEFAULT '0',
  inicio INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'abierto',
  fin INTEGER NULL,
  litros_sobrante TEXT NULL,
  evidencia_imagen_campo_uuid_cliente TEXT NULL,
  uuid_cliente_cierre TEXT NULL
);
CREATE UNIQUE INDEX idx_trabajo_local_uuid_cliente_cierre
  ON trabajo_local (uuid_cliente_cierre);

CREATE TABLE sesion_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  trabajo_uuid_cliente TEXT NOT NULL,
  secuencia INTEGER NOT NULL,
  piloto_id INTEGER NOT NULL,
  auxiliar_id INTEGER NULL,
  dron_id INTEGER NULL,
  hectareas_declaradas TEXT NOT NULL DEFAULT '0',
  hectarea_inicial_acumulada TEXT NULL,
  inicio INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'abierta',
  fin INTEGER NULL,
  motivo_cierre TEXT NULL,
  hectareas_declaradas_cierre TEXT NULL,
  litros_consumidos TEXT NULL,
  uuid_cliente_cierre TEXT NULL UNIQUE
);

CREATE TABLE condicion_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  sesion_uuid_cliente TEXT NOT NULL,
  momento TEXT NOT NULL,
  viento_kmh TEXT NOT NULL,
  temperatura_c TEXT NOT NULL,
  humedad_pct TEXT NOT NULL,
  observacion_agronomo TEXT NULL,
  firma_observacion TEXT NULL
);

CREATE TABLE evidencia_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  tipo TEXT NOT NULL,
  ruta_archivo_local TEXT NOT NULL,
  hash_sha256 TEXT NOT NULL,
  fecha INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  motivo_rechazo TEXT NULL
);

CREATE TABLE incidencia_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  sesion_uuid_cliente TEXT NOT NULL,
  tipo TEXT NOT NULL,
  descripcion TEXT NULL,
  hora INTEGER NOT NULL,
  evidencia_foto_uuid_cliente TEXT NOT NULL
);

CREATE TABLE trabajo_catalogo (
  id INTEGER NOT NULL PRIMARY KEY,
  uuid_cliente TEXT NOT NULL UNIQUE,
  orden_id INTEGER NOT NULL,
  lote_id INTEGER NOT NULL,
  hectareas_declaradas TEXT NOT NULL,
  equipo_trabajo_id INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  humedad_min_pct TEXT NULL,
  viento_max_kmh TEXT NULL,
  temperatura_max_c TEXT NULL,
  humedad_max_pct TEXT NULL,
  altura_vuelo_m TEXT NULL,
  velocidad_vuelo_kmh TEXT NULL,
  ancho_pasada_m TEXT NULL
);''';

void main() {
  test('base v13 preexistente migra a v14: agrega la marca de retiro en '
      'null, resetea el cursor y conserva todas las filas', () async {
    final rawDb = sqlite3.sqlite3.openInMemory();
    rawDb.execute(_createEsquemaV13);
    rawDb.execute('''
        INSERT INTO cola_sync
          (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
        VALUES
          ('sesion-preexistente', 'sesion', '{"trabajo_uuid_cliente":"uuid-panel-42"}', 1, 'pendiente', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO orden_catalogo
          (id, contrato_id, lote_id, cantidad_lotes, hectareas_solicitadas,
           nro_aplicacion, litros_ha, kilos_por_vuelo, observaciones,
           emitida_por_contacto_id, fecha_emision, estado, updated_at)
        VALUES
          (1, 4, 3, 2, '170.50', 2, '10.00', NULL, 'De mañana', 2,
           '2026-09-20', 'vigente', 1758369600),
          (2, 4, 6, 1, '45.00', 3, NULL, '8.50', NULL, NULL,
           '2026-09-21', 'vigente', 1758447000);
      ''');
    rawDb.execute('''
        INSERT INTO lote_catalogo (id, propiedad_id, codigo, hectareas, updated_at)
        VALUES (3, 1, 'L-01', '120.50', 1758369600);
      ''');
    rawDb.execute('''
        INSERT INTO persona_catalogo (id, nombre, rol, base_id, activo, updated_at)
        VALUES (5, 'Piloto Uno', 'piloto', 1, 1, 1758369600);
      ''');
    rawDb.execute('''
        INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-v13');
      ''');
    rawDb.execute('''
        INSERT INTO trabajo_catalogo
          (id, uuid_cliente, orden_id, lote_id, hectareas_declaradas,
           equipo_trabajo_id, updated_at, humedad_min_pct, viento_max_kmh,
           temperatura_max_c, humedad_max_pct, altura_vuelo_m,
           velocidad_vuelo_kmh, ancho_pasada_m)
        VALUES
          (42, 'uuid-panel-42', 1, 3, '300.00', 7, 1758542400, '40.00',
           '12.00', '28.00', '85.00', '3.00', '18.00', '7.00'),
          (43, 'uuid-panel-43', 2, 6, '45.00', 9, 1758542400, NULL,
           '17.00', '30.00', '90.00', NULL, NULL, NULL);
      ''');
    rawDb.execute('''
        INSERT INTO trabajo_local
          (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
        VALUES
          ('uuid-panel-42', 1, 3, 2, '0', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO sesion_local
          (uuid_cliente, trabajo_uuid_cliente, secuencia, piloto_id, inicio)
        VALUES
          ('sesion-preexistente', 'uuid-panel-42', 1, 5, 1700000100);
      ''');
    rawDb.execute('''
        INSERT INTO condicion_local
          (uuid_cliente, sesion_uuid_cliente, momento, viento_kmh,
           temperatura_c, humedad_pct)
        VALUES
          ('condicion-preexistente', 'sesion-preexistente', 'inicio_sesion', '12.0', '28.5', '65');
      ''');
    rawDb.execute('''
        INSERT INTO evidencia_local
          (uuid_cliente, tipo, ruta_archivo_local, hash_sha256, fecha)
        VALUES
          ('evidencia-preexistente', 'foto_incidencia', '/tmp/foto.jpg', 'abc123', 1700000200);
      ''');
    rawDb.execute('''
        INSERT INTO incidencia_local
          (uuid_cliente, sesion_uuid_cliente, tipo, hora, evidencia_foto_uuid_cliente)
        VALUES
          ('incidencia-preexistente', 'sesion-preexistente', 'otro', 1700000200, 'evidencia-preexistente');
      ''');
    rawDb.execute('PRAGMA user_version = 13;');

    final db = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(db.close);

    // Las órdenes se conservan con sus valores y la marca de retiro en null.
    final ordenes = await (db.select(
      db.ordenCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(ordenes.map((o) => o.id), [1, 2]);
    expect(ordenes[0].hectareasSolicitadas, Decimal.parse('170.50'));
    expect(ordenes[0].litrosHa, Decimal.parse('10.00'));
    expect(ordenes[0].observaciones, 'De mañana');
    expect(ordenes[1].kilosPorVuelo, Decimal.parse('8.50'));
    for (final orden in ordenes) {
      expect(orden.estado, 'vigente');
      expect(orden.motivoRetiro, isNull);
      expect(orden.retiroActualizadoEn, isNull);
      expect(orden.vistoEnBarrido, isNull);
    }

    // Los trabajos se conservan con sus límites y la marca en null.
    final trabajos = await (db.select(
      db.trabajoCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(trabajos.map((t) => t.uuidCliente), [
      'uuid-panel-42',
      'uuid-panel-43',
    ]);
    expect(trabajos[0].vientoMaxKmh, Decimal.parse('12.00'));
    expect(trabajos[0].humedadMinPct, Decimal.parse('40.00'));
    expect(trabajos[1].equipoTrabajoId, 9);
    for (final trabajo in trabajos) {
      expect(trabajo.motivoRetiro, isNull);
      expect(trabajo.retiroActualizadoEn, isNull);
      expect(trabajo.vistoEnBarrido, isNull);
    }

    // El cursor se resetea: el próximo pull es un barrido completo.
    expect(
      await (db.select(
        db.cursorCatalogo,
      )..where((t) => t.id.equals(0))).getSingleOrNull(),
      isNull,
    );

    // Nada del resto se perdió.
    expect((await db.select(db.loteCatalogo).get()).single.codigo, 'L-01');
    expect((await db.select(db.personaCatalogo).get()).single.id, 5);
    expect(
      (await db.select(db.colaSync).get()).single.uuidCliente,
      'sesion-preexistente',
    );
    expect(
      (await db.select(db.trabajoLocal).get()).single.uuidCliente,
      'uuid-panel-42',
    );
    expect(
      (await db.select(db.sesionLocal).get()).single.uuidCliente,
      'sesion-preexistente',
    );
    expect(
      (await db.select(db.condicionLocal).get()).single.uuidCliente,
      'condicion-preexistente',
    );
    expect(
      (await db.select(db.evidenciaLocal).get()).single.uuidCliente,
      'evidencia-preexistente',
    );
    expect(
      (await db.select(db.incidenciaLocal).get()).single.uuidCliente,
      'incidencia-preexistente',
    );

    // Las columnas nuevas son usables en las tres tablas.
    await (db.update(db.ordenCatalogo)..where((t) => t.id.equals(2))).write(
      OrdenCatalogoCompanion(
        motivoRetiro: const Value('pausada'),
        retiroActualizadoEn: Value(DateTime.utc(2026, 9, 25)),
      ),
    );
    await (db.update(db.trabajoCatalogo)..where((t) => t.id.equals(43))).write(
      const TrabajoCatalogoCompanion(
        motivoRetiro: Value('reasignado'),
        vistoEnBarrido: Value(false),
      ),
    );
    await db
        .into(db.cursorCatalogo)
        .insert(
          CursorCatalogoCompanion.insert(
            id: const Value(0),
            cursor: const Value('c1'),
            barridoEnCurso: const Value(true),
          ),
        );
    expect(
      (await (db.select(
        db.ordenCatalogo,
      )..where((t) => t.id.equals(2))).getSingle()).motivoRetiro,
      'pausada',
    );
    expect(
      (await (db.select(
        db.trabajoCatalogo,
      )..where((t) => t.id.equals(43))).getSingle()).motivoRetiro,
      'reasignado',
    );
    expect(
      (await db.select(db.cursorCatalogo).getSingle()).barridoEnCurso,
      isTrue,
    );
  });
}
