// Prueba de la migración de esquema v12 -> v13 (tarea 25): quita de
// `orden_catalogo` las ocho columnas de clima/vuelo que el servidor ya no
// manda en `ordenes[]`, CONSERVANDO las órdenes (`alterTable` +
// `TableMigration` copia las filas), y resetea el cursor para que los
// trabajos ya bajados reciban sus límites efectivos (`agrocom-api` #309 los
// cambió sin tocar `updated_at`).
//
// Mismo patrón que `migracion_limites_trabajo_test.dart` (v11 -> v12):
// esquema v12 completo escrito a mano con SQL crudo, `PRAGMA user_version =
// 12`, y recién ahí [AppDatabase] con el `schemaVersion` real. Las
// columnas nuevas de v12 se agregaron con `ALTER TABLE`, así que en un
// dispositivo real quedan al final de `trabajo_catalogo`: el SQL las pone
// en ese mismo orden.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v12 real: `orden_catalogo` todavía con sus
/// ocho columnas de clima/vuelo y `trabajo_catalogo` con los siete límites.
const _createEsquemaV12 = '''
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
  updated_at INTEGER NOT NULL,
  humedad_min_pct TEXT NULL,
  viento_max_kmh TEXT NULL,
  temperatura_max_c TEXT NULL,
  humedad_max_pct TEXT NULL,
  altura_vuelo_m TEXT NULL,
  velocidad_vuelo_kmh TEXT NULL,
  ancho_pasada_m TEXT NULL
);''';

const _columnasQuitadas = [
  'humedad_min_pct',
  'viento_max_kmh',
  'temperatura_max_c',
  'humedad_max_pct',
  'velocidad_max_kmh',
  'altura_vuelo_m',
  'velocidad_vuelo_kmh',
  'ancho_pasada_m',
];

void main() {
  test('base v12 preexistente migra a v13: orden_catalogo pierde las ocho '
      'columnas de clima/vuelo sin perder órdenes, el cursor se resetea y '
      'el resto de las tablas queda intacto', () async {
    final rawDb = sqlite3.sqlite3.openInMemory();
    rawDb.execute(_createEsquemaV12);
    rawDb.execute('''
        INSERT INTO cola_sync
          (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
        VALUES
          ('sesion-preexistente', 'sesion', '{"trabajo_uuid_cliente":"uuid-panel-42"}', 1, 'pendiente', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO orden_catalogo
          (id, contrato_id, lote_id, cantidad_lotes, hectareas_solicitadas,
           nro_aplicacion, litros_ha, kilos_por_vuelo, humedad_min_pct,
           viento_max_kmh, temperatura_max_c, humedad_max_pct,
           velocidad_max_kmh, altura_vuelo_m, velocidad_vuelo_kmh,
           ancho_pasada_m, observaciones, emitida_por_contacto_id,
           fecha_emision, estado, updated_at)
        VALUES
          (1, 4, 3, 2, '170.50', 2, '10.00', NULL, '60.00', '15.00',
           '32.00', '90.00', '25.00', '3.00', '18.00', '7.00',
           'De mañana', 2, '2026-09-20', 'vigente', 1758369600),
          (2, 4, 6, 1, '45.00', 3, NULL, '8.50', NULL, NULL, NULL, NULL,
           NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-21', 'vigente',
           1758447000);
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
        INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-v12');
      ''');
    rawDb.execute('''
        INSERT INTO trabajo_catalogo
          (id, uuid_cliente, orden_id, lote_id, hectareas_declaradas,
           equipo_trabajo_id, updated_at, humedad_min_pct, viento_max_kmh,
           temperatura_max_c, humedad_max_pct, altura_vuelo_m,
           velocidad_vuelo_kmh, ancho_pasada_m)
        VALUES
          (42, 'uuid-panel-42', 1, 3, '300.00', 7, 1758542400, '40.00',
           '12.00', '28.00', '85.00', '3.00', '18.00', '7.00');
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
    rawDb.execute('PRAGMA user_version = 12;');

    final db = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(db.close);

    // `orden_catalogo` ya no tiene las ocho columnas de clima/vuelo.
    final columnas =
        (await db.customSelect('PRAGMA table_info(orden_catalogo)').get())
            .map((fila) => fila.read<String>('name'))
            .toSet();
    for (final columna in _columnasQuitadas) {
      expect(columnas, isNot(contains(columna)), reason: columna);
    }

    // Las dos órdenes se conservan con todos los valores que siguen
    // existiendo.
    final ordenes = await (db.select(
      db.ordenCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(ordenes.map((o) => o.id), [1, 2]);
    final liquida = ordenes[0];
    expect(liquida.contratoId, 4);
    expect(liquida.loteId, 3);
    expect(liquida.cantidadLotes, 2);
    expect(liquida.hectareasSolicitadas, Decimal.parse('170.50'));
    expect(liquida.nroAplicacion, 2);
    expect(liquida.litrosHa, Decimal.parse('10.00'));
    expect(liquida.kilosPorVuelo, isNull);
    expect(liquida.observaciones, 'De mañana');
    expect(liquida.emitidaPorContactoId, 2);
    expect(liquida.fechaEmision, '2026-09-20');
    expect(liquida.estado, 'vigente');
    expect(
      liquida.updatedAt.isAtSameMomentAs(
        DateTime.fromMillisecondsSinceEpoch(1758369600 * 1000),
      ),
      isTrue,
    );
    final solida = ordenes[1];
    expect(solida.litrosHa, isNull);
    expect(solida.kilosPorVuelo, Decimal.parse('8.50'));
    expect(solida.observaciones, isNull);

    // El cursor se resetea: el próximo pull trae de nuevo los trabajos con
    // sus límites efectivos.
    expect(
      await (db.select(
        db.cursorCatalogo,
      )..where((t) => t.id.equals(0))).getSingleOrNull(),
      isNull,
    );

    // `trabajo_catalogo` no se toca: conserva sus límites.
    final trabajo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(trabajo.uuidCliente, 'uuid-panel-42');
    expect(trabajo.humedadMinPct, Decimal.parse('40.00'));
    expect(trabajo.vientoMaxKmh, Decimal.parse('12.00'));
    expect(trabajo.temperaturaMaxC, Decimal.parse('28.00'));
    expect(trabajo.humedadMaxPct, Decimal.parse('85.00'));
    expect(trabajo.alturaVueloM, Decimal.parse('3.00'));
    expect(trabajo.velocidadVueloKmh, Decimal.parse('18.00'));
    expect(trabajo.anchoPasadaM, Decimal.parse('7.00'));

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

    // La tabla recreada sigue usable: el upsert del pull escribe sobre ella.
    await db
        .into(db.ordenCatalogo)
        .insertOnConflictUpdate(
          OrdenCatalogoCompanion.insert(
            id: const Value(1),
            contratoId: 4,
            loteId: 3,
            nroAplicacion: 2,
            observaciones: const Value('Actualizada'),
            fechaEmision: '2026-09-20',
            estado: 'vigente',
            updatedAt: DateTime.utc(2026, 9, 23),
          ),
        );
    expect(
      (await (db.select(
        db.ordenCatalogo,
      )..where((t) => t.id.equals(1))).getSingle()).observaciones,
      'Actualizada',
    );
    expect(await db.select(db.ordenCatalogo).get(), hasLength(2));
  });
}
