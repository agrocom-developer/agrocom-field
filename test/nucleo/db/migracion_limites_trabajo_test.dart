// Prueba de la migración de esquema v11 -> v12 (tarea 23): agrega a
// `trabajo_catalogo` los siete límites climáticos y parámetros de vuelo que
// el servidor movió de `ordenes[]` a `trabajos[]`, con `ALTER TABLE`, sin
// perder ninguna fila, y resetea el cursor para que el próximo pull vuelva a
// traer los trabajos y complete las columnas nuevas.
//
// Mismo patrón que `migracion_trabajo_catalogo_test.dart` (v10 -> v11):
// esquema v11 completo escrito a mano con SQL crudo, `PRAGMA user_version =
// 11`, y recién ahí [AppDatabase] con el `schemaVersion` real.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v11 real: el v10 más `trabajo_catalogo` sin
/// los límites climáticos ni los parámetros de vuelo. `orden_catalogo`
/// conserva sus columnas de clima/vuelo (v12 no las borra).
const _createEsquemaV11 = '''
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
  humedad_min_pct TEXT NULL,
  viento_max_kmh TEXT NULL,
  temperatura_max_c TEXT NULL,
  humedad_max_pct TEXT NULL,
  velocidad_max_kmh TEXT NULL,
  altura_vuelo_m TEXT NULL,
  velocidad_vuelo_kmh TEXT NULL,
  ancho_pasada_m TEXT NULL,
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
  updated_at INTEGER NOT NULL
);''';

void main() {
  test('base v11 preexistente migra a v12: agrega los límites a '
      'trabajo_catalogo en null, resetea el cursor y conserva todas las '
      'filas', () async {
    final rawDb = sqlite3.sqlite3.openInMemory();
    rawDb.execute(_createEsquemaV11);
    rawDb.execute('''
        INSERT INTO cola_sync
          (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
        VALUES
          ('sesion-preexistente', 'sesion', '{"trabajo_uuid_cliente":"uuid-panel-42"}', 1, 'pendiente', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO orden_catalogo
          (id, contrato_id, lote_id, cantidad_lotes, hectareas_solicitadas,
           nro_aplicacion, litros_ha, viento_max_kmh, fecha_emision, estado,
           updated_at)
        VALUES
          (1, 4, 3, 2, '170.50', 2, '10.00', '15.00', '2026-09-20', 'vigente', 1758369600);
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
        INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-v11');
      ''');
    rawDb.execute('''
        INSERT INTO trabajo_catalogo
          (id, uuid_cliente, orden_id, lote_id, hectareas_declaradas,
           equipo_trabajo_id, updated_at)
        VALUES
          (42, 'uuid-panel-42', 1, 3, '300.00', 7, 1758542400);
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
          ('condicion-preexistente', 'sesion-preexistente', 'inicio', '12.0', '28.5', '65');
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
    rawDb.execute('PRAGMA user_version = 11;');

    final db = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(db.close);

    // El trabajo bajado antes de v12 se conserva, con las columnas nuevas
    // en null hasta el próximo pull.
    final trabajo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(trabajo.id, 42);
    expect(trabajo.uuidCliente, 'uuid-panel-42');
    expect(trabajo.hectareasDeclaradas, Decimal.parse('300.00'));
    expect(trabajo.equipoTrabajoId, 7);
    expect(trabajo.humedadMinPct, isNull);
    expect(trabajo.vientoMaxKmh, isNull);
    expect(trabajo.temperaturaMaxC, isNull);
    expect(trabajo.humedadMaxPct, isNull);
    expect(trabajo.alturaVueloM, isNull);
    expect(trabajo.velocidadVueloKmh, isNull);
    expect(trabajo.anchoPasadaM, isNull);

    // Nada de lo anterior se perdió; `orden_catalogo` conserva incluso sus
    // columnas de clima/vuelo (v12 no las borra).
    final orden = (await db.select(db.ordenCatalogo).get()).single;
    expect(orden.cantidadLotes, 2);
    expect(orden.vientoMaxKmh, Decimal.parse('15.00'));
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

    // El cursor se resetea para que el próximo pull complete los límites.
    expect(
      await (db.select(
        db.cursorCatalogo,
      )..where((t) => t.id.equals(0))).getSingleOrNull(),
      isNull,
    );

    // Las columnas nuevas son usables: el upsert del pull las completa sobre
    // la fila conservada.
    await db
        .into(db.trabajoCatalogo)
        .insertOnConflictUpdate(
          TrabajoCatalogoCompanion.insert(
            id: const Value(42),
            uuidCliente: 'uuid-panel-42',
            ordenId: 1,
            loteId: 3,
            hectareasDeclaradas: Decimal.parse('300.00'),
            equipoTrabajoId: 7,
            humedadMinPct: Value(Decimal.parse('60.00')),
            vientoMaxKmh: Value(Decimal.parse('15.00')),
            temperaturaMaxC: Value(Decimal.parse('32.00')),
            humedadMaxPct: Value(Decimal.parse('90.00')),
            alturaVueloM: Value(Decimal.parse('3.00')),
            velocidadVueloKmh: Value(Decimal.parse('18.00')),
            anchoPasadaM: Value(Decimal.parse('7.00')),
            updatedAt: DateTime.utc(2026, 9, 22, 12),
          ),
        );
    final completo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(completo.humedadMinPct, Decimal.parse('60.00'));
    expect(completo.vientoMaxKmh, Decimal.parse('15.00'));
    expect(completo.temperaturaMaxC, Decimal.parse('32.00'));
    expect(completo.humedadMaxPct, Decimal.parse('90.00'));
    expect(completo.alturaVueloM, Decimal.parse('3.00'));
    expect(completo.velocidadVueloKmh, Decimal.parse('18.00'));
    expect(completo.anchoPasadaM, Decimal.parse('7.00'));
  });
}
