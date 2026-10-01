// Prueba de la migración de esquema v10 -> v11 (HU-70): agrega
// `trabajo_catalogo`, el espejo de solo lectura de `trabajos[]` del pull de
// catálogo, sin tocar ninguna tabla anterior, y resetea el cursor para que
// los trabajos asignados que el pull ignoraba hasta v10 vuelvan a bajar.
//
// Mismo patrón que `migracion_lotes_orden_test.dart` (v9 -> v10): esquema
// v10 completo escrito a mano con SQL crudo, `PRAGMA user_version = 10`, y
// recién ahí [AppDatabase] con el `schemaVersion` real.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v10 real: el v9 más `cantidad_lotes` y
/// `hectareas_solicitadas` en `orden_catalogo` (TE-23). Sin
/// `trabajo_catalogo`.
const _createEsquemaV10 = '''
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
''';

void main() {
  test('base v10 preexistente migra a v11: crea trabajo_catalogo usable, '
      'resetea el cursor y conserva órdenes, lotes, cola_sync, trabajo_local '
      'y sesion_local', () async {
    final rawDb = sqlite3.sqlite3.openInMemory();
    rawDb.execute(_createEsquemaV10);
    rawDb.execute('''
        INSERT INTO cola_sync
          (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
        VALUES
          ('trabajo-preexistente', 'trabajo', '{"orden_id":1}', 1, 'pendiente', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO orden_catalogo
          (id, contrato_id, lote_id, cantidad_lotes, hectareas_solicitadas,
           nro_aplicacion, litros_ha, fecha_emision, estado, updated_at)
        VALUES
          (1, 4, 3, 2, '170.50', 2, '10.00', '2026-09-20', 'vigente', 1758369600);
      ''');
    rawDb.execute('''
        INSERT INTO lote_catalogo (id, propiedad_id, codigo, hectareas, updated_at)
        VALUES (3, 1, 'L-01', '120.50', 1758369600);
      ''');
    rawDb.execute('''
        INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-v10');
      ''');
    rawDb.execute('''
        INSERT INTO trabajo_local
          (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
        VALUES
          ('trabajo-preexistente', 1, 3, 2, '0', 1700000000);
      ''');
    rawDb.execute('''
        INSERT INTO sesion_local
          (uuid_cliente, trabajo_uuid_cliente, secuencia, piloto_id, inicio)
        VALUES
          ('sesion-preexistente', 'trabajo-preexistente', 1, 5, 1700000100);
      ''');
    rawDb.execute('PRAGMA user_version = 10;');

    final db = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(db.close);

    // Nada de lo anterior se perdió.
    final orden = (await db.select(db.ordenCatalogo).get()).single;
    expect(orden.cantidadLotes, 2);
    expect(orden.hectareasSolicitadas, Decimal.parse('170.50'));
    expect((await db.select(db.loteCatalogo).get()).single.codigo, 'L-01');
    expect(
      (await db.select(db.colaSync).get()).single.uuidCliente,
      'trabajo-preexistente',
    );
    expect(
      (await db.select(db.trabajoLocal).get()).single.uuidCliente,
      'trabajo-preexistente',
    );
    expect(
      (await db.select(db.sesionLocal).get()).single.uuidCliente,
      'sesion-preexistente',
    );

    // El cursor se resetea para que bajen los trabajos ya asignados.
    expect(
      await (db.select(
        db.cursorCatalogo,
      )..where((t) => t.id.equals(0))).getSingleOrNull(),
      isNull,
    );

    // La tabla nueva existe, vacía y usable.
    expect(await db.select(db.trabajoCatalogo).get(), isEmpty);
    await db
        .into(db.trabajoCatalogo)
        .insert(
          TrabajoCatalogoCompanion.insert(
            id: const Value(42),
            uuidCliente: '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a',
            ordenId: 1,
            loteId: 3,
            hectareasDeclaradas: Decimal.parse('300.00'),
            equipoTrabajoId: 7,
            updatedAt: DateTime.utc(2026, 9, 22, 12),
          ),
        );
    final trabajo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(trabajo.uuidCliente, '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a');
    expect(trabajo.hectareasDeclaradas, Decimal.parse('300.00'));

    // `uuid_cliente` es único: otra fila con el mismo uuid falla.
    await expectLater(
      db
          .into(db.trabajoCatalogo)
          .insert(
            TrabajoCatalogoCompanion.insert(
              id: const Value(43),
              uuidCliente: '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a',
              ordenId: 1,
              loteId: 3,
              hectareasDeclaradas: Decimal.parse('1'),
              equipoTrabajoId: 7,
              updatedAt: DateTime.utc(2026, 9, 22, 12),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
