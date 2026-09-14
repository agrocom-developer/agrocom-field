// Prueba de la migración de esquema v5 -> v6 (HU-08: incidencia con foto).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. Esta prueba ejercita el
// `onUpgrade` real (no lo simula), siguiendo el mismo patrón que
// `migracion_evidencia_test.dart`: arma a mano, con SQL crudo, el esquema v5
// completo tal como quedó en dispositivos reales (`cola_sync` + las 4 tablas
// de catálogo de TE-06 + `trabajo_local`/`sesion_local` de HU-05 +
// `condicion_local` de HU-06 + `evidencia_local` de TE-07, con datos reales
// preexistentes en varias de ellas), fija `PRAGMA user_version = 5` y recién
// ahí abre [AppDatabase] con `schemaVersion = 6` sobre el mismo executor —
// drift detecta el `user_version` viejo y dispara `onUpgrade(m, 5, 6)` de
// verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/db/tablas/evidencia_local.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v5 real: `cola_sync` de v1 + las 4 tablas de
/// catálogo de TE-06 (v2) + `trabajo_local`/`sesion_local` de HU-05 (v3) +
/// `condicion_local` de HU-06 (v4) + `evidencia_local` de TE-07 (v5), tal
/// como quedaron creadas en dispositivos reales.
const _createEsquemaV5 = '''
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
  litros_ha TEXT NOT NULL,
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
  inicio INTEGER NOT NULL
);

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
''';

Future<void> _insertarIncidenciaDePrueba(
  AppDatabase db, {
  String sufijo = '',
  String tipo = 'mecanica',
  String? descripcion,
}) {
  return db
      .into(db.incidenciaLocal)
      .insert(
        IncidenciaLocalCompanion.insert(
          uuidCliente: 'incidencia-$sufijo',
          sesionUuidCliente: 'sesion-preexistente',
          tipo: tipo,
          descripcion: Value(descripcion),
          hora: DateTime.utc(2026, 9, 11, 9),
          evidenciaFotoUuidCliente: 'evidencia-$sufijo',
        ),
      );
}

void main() {
  group('migración de esquema drift (HU-08: incidencia con foto)', () {
    test('base nueva sin historial: onCreate deja incidencia_local creada '
        'y usable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await _insertarIncidenciaDePrueba(
        db,
        sufijo: 'a',
        tipo: 'esc',
        descripcion: 'ESC trasero izquierdo caliente',
      );
      final incidencia = (await db.select(db.incidenciaLocal).get()).single;
      expect(incidencia.uuidCliente, 'incidencia-a');
      expect(incidencia.sesionUuidCliente, 'sesion-preexistente');
      expect(incidencia.tipo, 'esc');
      expect(incidencia.descripcion, 'ESC trasero izquierdo caliente');
      expect(incidencia.evidenciaFotoUuidCliente, 'evidencia-a');
    });

    test('base v5 preexistente con datos reales en cola_sync, sesion_local, '
        'condicion_local y evidencia_local migra a v6 sin perderlos, y '
        'incidencia_local queda creada y usable', () async {
      // Arma a mano el estado "v5 preexistente" — el mismo que ya corrió
      // en dispositivos reales — sobre un sqlite3.Database crudo, antes de
      // que drift lo toque.
      final rawDb = sqlite3.sqlite3.openInMemory();
      rawDb.execute(_createEsquemaV5);
      rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v5', 'sesion', '{"piloto_id":7}', 1, 'confirmado', 1700000000);
        ''');
      rawDb.execute('''
          INSERT INTO trabajo_local
            (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
          VALUES
            ('trabajo-preexistente', 1, 1, 1, '0', 1700000000);
        ''');
      rawDb.execute('''
          INSERT INTO sesion_local
            (uuid_cliente, trabajo_uuid_cliente, secuencia, piloto_id, hectareas_declaradas, inicio, estado)
          VALUES
            ('sesion-preexistente', 'trabajo-preexistente', 1, 7, '0', 1700000300, 'abierta');
        ''');
      rawDb.execute('''
          INSERT INTO condicion_local
            (uuid_cliente, sesion_uuid_cliente, momento, viento_kmh, temperatura_c, humedad_pct)
          VALUES
            ('condicion-preexistente', 'sesion-preexistente', 'inicio_sesion', '12.50', '24.00', '65.00');
        ''');
      rawDb.execute('''
          INSERT INTO evidencia_local
            (uuid_cliente, tipo, ruta_archivo_local, hash_sha256, fecha, estado)
          VALUES
            ('evidencia-preexistente', 'foto_incidencia', '/evidencias/evidencia-preexistente.jpg', '${'a' * 64}', 1700000400, 'subido');
        ''');
      rawDb.execute('PRAGMA user_version = 5;');

      // Mismo executor, ahora abierto por AppDatabase (schemaVersion 6):
      // drift compara el user_version (5) recién fijado contra
      // schemaVersion y dispara onUpgrade(m, 5, 6) de verdad.
      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(db.close);

      final filasColaSync = await db.select(db.colaSync).get();
      expect(
        filasColaSync,
        hasLength(1),
        reason:
            'la fila sembrada en v5 no debe perderse ni duplicarse al migrar',
      );
      expect(filasColaSync.single.uuidCliente, 'preexistente-v5');
      expect(filasColaSync.single.estado, EstadoSync.confirmado);

      final filasSesion = await db.select(db.sesionLocal).get();
      expect(
        filasSesion,
        hasLength(1),
        reason:
            'la sesión ya abierta en v5 no debe perderse ni duplicarse al '
            'migrar',
      );
      expect(filasSesion.single.uuidCliente, 'sesion-preexistente');

      final filasCondicion = await db.select(db.condicionLocal).get();
      expect(
        filasCondicion,
        hasLength(1),
        reason:
            'la condición ya capturada en v5 no debe perderse ni '
            'duplicarse al migrar',
      );
      expect(filasCondicion.single.uuidCliente, 'condicion-preexistente');

      final filasEvidencia = await db.select(db.evidenciaLocal).get();
      expect(
        filasEvidencia,
        hasLength(1),
        reason:
            'la evidencia ya subida en v5 no debe perderse ni duplicarse '
            'al migrar',
      );
      expect(filasEvidencia.single.uuidCliente, 'evidencia-preexistente');
      expect(filasEvidencia.single.estado, EstadoEvidenciaLocal.subido);

      // incidencia_local no existía en v5: si onUpgrade no la creó, estos
      // insert+select fallarían con "no such table".
      await _insertarIncidenciaDePrueba(
        db,
        sufijo: 'nueva',
        tipo: 'clima',
        descripcion: 'Ráfagas fuertes, se aborta la pasada',
      );
      await _insertarIncidenciaDePrueba(db, sufijo: 'sin-descripcion');

      final filasIncidencia = await db.select(db.incidenciaLocal).get();
      expect(filasIncidencia, hasLength(2));

      final conDescripcion = filasIncidencia.firstWhere(
        (i) => i.uuidCliente == 'incidencia-nueva',
      );
      expect(conDescripcion.sesionUuidCliente, 'sesion-preexistente');
      expect(conDescripcion.tipo, 'clima');
      expect(
        conDescripcion.descripcion,
        'Ráfagas fuertes, se aborta la pasada',
      );
      expect(conDescripcion.evidenciaFotoUuidCliente, 'evidencia-nueva');

      final sinDescripcion = filasIncidencia.firstWhere(
        (i) => i.uuidCliente == 'incidencia-sin-descripcion',
      );
      expect(sinDescripcion.descripcion, isNull);
    });
  });
}
