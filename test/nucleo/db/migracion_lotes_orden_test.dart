// Prueba de la migración de esquema v9 -> v10 (TE-23, ADR 0022 de
// `agrocom-api`: `lotes[]` de una orden es la copia de TODOS los lotes del
// contrato). `orden_catalogo` gana `cantidad_lotes` y `hectareas_solicitadas`
// por `ALTER TABLE`: a diferencia de v8/v9, esta migración CONSERVA las
// órdenes ya bajadas (columnas nuevas en `null`) y solo resetea el cursor,
// para que el próximo pull las vuelva a traer completas.
//
// Mismo patrón que `migracion_propiedad_test.dart` (v8 -> v9): arma a mano,
// con SQL crudo, el esquema v9 completo tal como quedó en dispositivos
// reales, fija `PRAGMA user_version = 9` y recién ahí abre [AppDatabase] con
// el `schemaVersion` real — drift dispara `onUpgrade(m, 9, 10)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v9 real: igual al v8 salvo `lote_catalogo`, que
/// ya tiene `propiedad_id` (ADR 0020). `orden_catalogo` todavía SIN
/// `cantidad_lotes`/`hectareas_solicitadas`.
const _createEsquemaV9 = '''
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
  group('migración de esquema drift (TE-23: lotes de la orden, v9 -> v10)', () {
    test('base v9 preexistente migra a v10 conservando las órdenes bajadas '
        '(columnas nuevas en null), resetea el cursor y no toca cola_sync, '
        'trabajo_local ni lote_catalogo', () async {
      final rawDb = sqlite3.sqlite3.openInMemory();
      rawDb.execute(_createEsquemaV9);
      rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v9', 'trabajo', '{"orden_id":1}', 1, 'confirmado', 1700000000);
        ''');
      rawDb.execute('''
          INSERT INTO orden_catalogo
            (id, contrato_id, lote_id, nro_aplicacion, litros_ha,
             kilos_por_vuelo, viento_max_kmh, velocidad_max_kmh, observaciones,
             fecha_emision, estado, updated_at)
          VALUES
            (1, 4, 3, 2, '10.00', NULL, '15.00', '25.00', 'De mañana',
             '2026-09-20', 'vigente', 1758369600),
            (2, 4, 5, 1, NULL, '8.50', NULL, NULL, NULL,
             '2026-09-21', 'vigente', 1758456000);
        ''');
      rawDb.execute('''
          INSERT INTO lote_catalogo
            (id, propiedad_id, codigo, hectareas, updated_at)
          VALUES
            (3, 1, 'L-01', '120.50', 1758369600);
        ''');
      rawDb.execute('''
          INSERT INTO cursor_catalogo (id, cursor) VALUES (0, 'cursor-v9');
        ''');
      rawDb.execute('''
          INSERT INTO trabajo_local
            (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
          VALUES
            ('trabajo-preexistente', 1, 3, 2, '37.40', 1700000000);
        ''');
      rawDb.execute('PRAGMA user_version = 9;');

      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(db.close);

      // Las órdenes se conservan, con todos sus valores intactos y las
      // columnas nuevas en null hasta el próximo pull.
      final ordenes = await (db.select(
        db.ordenCatalogo,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(ordenes.map((o) => o.id), [1, 2]);
      expect(ordenes[0].contratoId, 4);
      expect(ordenes[0].loteId, 3);
      expect(ordenes[0].nroAplicacion, 2);
      expect(ordenes[0].litrosHa, Decimal.parse('10.00'));
      expect(ordenes[0].kilosPorVuelo, isNull);
      expect(ordenes[0].vientoMaxKmh, Decimal.parse('15.00'));
      expect(ordenes[0].velocidadMaxKmh, Decimal.parse('25.00'));
      expect(ordenes[0].observaciones, 'De mañana');
      expect(ordenes[0].fechaEmision, '2026-09-20');
      expect(ordenes[1].litrosHa, isNull);
      expect(ordenes[1].kilosPorVuelo, Decimal.parse('8.50'));
      for (final orden in ordenes) {
        expect(orden.cantidadLotes, isNull);
        expect(orden.hectareasSolicitadas, isNull);
      }

      // El cursor se resetea: el próximo pull trae todo y completa las
      // columnas nuevas de las órdenes conservadas.
      expect(
        await (db.select(
          db.cursorCatalogo,
        )..where((t) => t.id.equals(0))).getSingleOrNull(),
        isNull,
      );

      // Nada más se tocó.
      final lotes = await db.select(db.loteCatalogo).get();
      expect(lotes.single.codigo, 'L-01');
      expect(lotes.single.hectareas, Decimal.parse('120.50'));
      expect(
        (await db.select(db.colaSync).get()).single.uuidCliente,
        'preexistente-v9',
      );
      expect(
        (await db.select(db.trabajoLocal).get()).single.uuidCliente,
        'trabajo-preexistente',
      );

      // Las columnas nuevas quedan usables: un upsert del pull las llena
      // sobre la fila conservada.
      await db
          .into(db.ordenCatalogo)
          .insertOnConflictUpdate(
            ordenes[0]
                .toCompanion(false)
                .copyWith(
                  cantidadLotes: const Value(2),
                  hectareasSolicitadas: Value(Decimal.parse('170.50')),
                ),
          );
      final actualizada = await (db.select(
        db.ordenCatalogo,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(actualizada.cantidadLotes, 2);
      expect(actualizada.hectareasSolicitadas, Decimal.parse('170.50'));
    });
  });
}
