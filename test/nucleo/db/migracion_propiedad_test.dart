// Prueba de la migración de esquema v8 -> v9 (ADR 0020 de `agrocom-api`: el
// servidor elimina la entidad `Campo` — `Lote` cuelga directo de
// `Propiedad`, `lote_catalogo.campo_id` pasa a `propiedad_id`).
//
// Mismo criterio que `migracion_orden_catalogo_lotes_test.dart` (v7 -> v8):
// `lote_catalogo` es un espejo de solo lectura de catálogo, nunca datos
// capturados sin conectividad, así que es seguro perder el catálogo viejo y
// dejar que el próximo pull la repueble entera con el contrato nuevo. Arma a
// mano, con SQL crudo, el esquema v8 completo tal como quedó en dispositivos
// reales, fija `PRAGMA user_version = 8` y recién ahí abre [AppDatabase] con
// el `schemaVersion` real — drift dispara `onUpgrade(m, 8, 9)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v8 real: `orden_catalogo` ya con el contrato
/// de TE-20 (`litros_ha` nullable, `kilos_por_vuelo`); `lote_catalogo` acá es
/// DELIBERADAMENTE el esquema VIEJO (`campo_id`) que esta migración recrea.
const _createEsquemaV8 = '''
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
  campo_id INTEGER NOT NULL,
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
  group('migración de esquema drift (ADR 0020: propiedad_id en LoteCatalogo)', () {
    test(
      'base v8 preexistente con catálogo y cursor del esquema viejo migra a '
      'v9: pierde el catálogo de lotes viejo a propósito, pero no toca '
      'cola_sync ni trabajo_local, y la tabla queda usable con el contrato '
      'nuevo (propiedad_id)',
      () async {
        // Arma a mano el estado "v8 preexistente" sobre un sqlite3.Database
        // crudo, antes de que drift lo toque.
        final rawDb = sqlite3.sqlite3.openInMemory();
        rawDb.execute(_createEsquemaV8);
        rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v8', 'trabajo', '{"orden_id":1}', 1, 'confirmado', 1700000000);
        ''');
        rawDb.execute('''
          INSERT INTO lote_catalogo
            (id, campo_id, codigo, hectareas, updated_at)
          VALUES
            (1, 5, 'L-1', '120.75', 1756209600000);
        ''');
        rawDb.execute('''
          INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-viejo');
        ''');
        rawDb.execute('''
          INSERT INTO trabajo_local
            (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
          VALUES
            ('trabajo-preexistente', 5, 9, 2, '37.40', 1700000000);
        ''');
        rawDb.execute('PRAGMA user_version = 8;');

        // Mismo executor, ahora abierto por AppDatabase (schemaVersion real):
        // drift compara el user_version (8) recién fijado contra
        // schemaVersion y dispara onUpgrade(m, 8, 9) de verdad.
        final db = AppDatabase(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        // El catálogo de lotes viejo se pierde a propósito (ver comentario
        // de cabecera) — y el cursor se resetea con él, para que el próximo
        // pull traiga las cuatro secciones desde cero.
        expect(await db.select(db.loteCatalogo).get(), isEmpty);
        expect(
          await (db.select(
            db.cursorCatalogo,
          )..where((t) => t.id.equals(0))).getSingleOrNull(),
          isNull,
        );

        // Nada de lo que protege la invariante 10 de CLAUDE.md se tocó.
        final filasColaSync = await db.select(db.colaSync).get();
        expect(filasColaSync, hasLength(1));
        expect(filasColaSync.single.uuidCliente, 'preexistente-v8');

        final filasTrabajo = await db.select(db.trabajoLocal).get();
        expect(filasTrabajo, hasLength(1));
        expect(filasTrabajo.single.uuidCliente, 'trabajo-preexistente');

        // La tabla sigue creada y usable, ahora con el contrato nuevo:
        // propiedad_id en vez de campo_id.
        await db
            .into(db.loteCatalogo)
            .insert(
              LoteCatalogoCompanion.insert(
                id: const Value(2),
                propiedadId: 7,
                codigo: 'L-2',
                hectareas: Decimal.parse('80.00'),
                updatedAt: DateTime.utc(2026, 9, 15),
              ),
            );
        final loteNuevo = (await db.select(db.loteCatalogo).get()).single;
        expect(loteNuevo.propiedadId, 7);
        expect(loteNuevo.hectareas, Decimal.parse('80.00'));
      },
    );
  });
}
