// Prueba de la migración de esquema v4 -> v5 (TE-07: cola de evidencias).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. Esta prueba ejercita el
// `onUpgrade` real (no lo simula), siguiendo el mismo patrón que
// `migracion_condicion_test.dart`: arma a mano, con SQL crudo, el esquema v4
// completo tal como quedó en dispositivos reales (`cola_sync` + las 4 tablas
// de catálogo de TE-06 + `trabajo_local`/`sesion_local` de HU-05 +
// `condicion_local` de HU-06, con datos reales preexistentes en varias de
// ellas), fija `PRAGMA user_version = 4` y recién ahí abre [AppDatabase] con
// `schemaVersion = 5` sobre el mismo executor — drift detecta el
// `user_version` viejo y dispara `onUpgrade(m, 4, 5)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/db/tablas/evidencia_local.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v4 real: `cola_sync` de v1 + las 4 tablas de
/// catálogo de TE-06 (v2) + `trabajo_local`/`sesion_local` de HU-05 (v3) +
/// `condicion_local` de HU-06 (v4), tal como quedaron creadas en
/// dispositivos reales.
const _createEsquemaV4 = '''
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
''';

Future<void> _insertarEvidenciaDePrueba(
  AppDatabase db, {
  String sufijo = '',
  EstadoEvidenciaLocal estado = EstadoEvidenciaLocal.pendiente,
  String? motivoRechazo,
}) {
  return db
      .into(db.evidenciaLocal)
      .insert(
        EvidenciaLocalCompanion.insert(
          uuidCliente: 'evidencia-$sufijo',
          tipo: 'foto_incidencia',
          rutaArchivoLocal: '/evidencias/evidencia-$sufijo.jpg',
          hashSha256: 'a' * 64,
          fecha: DateTime.utc(2026, 9, 11, 9),
          estado: Value(estado),
          motivoRechazo: Value(motivoRechazo),
        ),
      );
}

void main() {
  group('migración de esquema drift (TE-07: cola de evidencias)', () {
    test('base nueva sin historial: onCreate deja evidencia_local creada y '
        'usable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await _insertarEvidenciaDePrueba(db, sufijo: 'a');
      final evidencia = (await db.select(db.evidenciaLocal).get()).single;
      expect(evidencia.uuidCliente, 'evidencia-a');
      expect(evidencia.tipo, 'foto_incidencia');
      expect(evidencia.rutaArchivoLocal, '/evidencias/evidencia-a.jpg');
      expect(evidencia.hashSha256, 'a' * 64);
      expect(evidencia.estado, EstadoEvidenciaLocal.pendiente);
      expect(evidencia.motivoRechazo, isNull);
    });

    test('base v4 preexistente con datos reales en cola_sync, sesion_local y '
        'condicion_local migra a v5 sin perderlos, y evidencia_local queda '
        'creada y usable', () async {
      // Arma a mano el estado "v4 preexistente" — el mismo que ya corrió
      // en dispositivos reales — sobre un sqlite3.Database crudo, antes de
      // que drift lo toque.
      final rawDb = sqlite3.sqlite3.openInMemory();
      rawDb.execute(_createEsquemaV4);
      rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v4', 'sesion', '{"piloto_id":7}', 1, 'confirmado', 1700000000);
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
      rawDb.execute('PRAGMA user_version = 4;');

      // Mismo executor, ahora abierto por AppDatabase (schemaVersion 5):
      // drift compara el user_version (4) recién fijado contra
      // schemaVersion y dispara onUpgrade(m, 4, 5) de verdad.
      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(db.close);

      final filasColaSync = await db.select(db.colaSync).get();
      expect(
        filasColaSync,
        hasLength(1),
        reason:
            'la fila sembrada en v4 no debe perderse ni duplicarse al migrar',
      );
      expect(filasColaSync.single.uuidCliente, 'preexistente-v4');
      expect(filasColaSync.single.estado, EstadoSync.confirmado);

      final filasSesion = await db.select(db.sesionLocal).get();
      expect(
        filasSesion,
        hasLength(1),
        reason:
            'la sesión ya abierta en v4 no debe perderse ni duplicarse al '
            'migrar',
      );
      expect(filasSesion.single.uuidCliente, 'sesion-preexistente');

      final filasCondicion = await db.select(db.condicionLocal).get();
      expect(
        filasCondicion,
        hasLength(1),
        reason:
            'la condición ya capturada en v4 no debe perderse ni '
            'duplicarse al migrar',
      );
      expect(filasCondicion.single.uuidCliente, 'condicion-preexistente');

      // evidencia_local no existía en v4: si onUpgrade no la creó, estos
      // insert+select fallarían con "no such table".
      await _insertarEvidenciaDePrueba(db, sufijo: 'nueva');
      await _insertarEvidenciaDePrueba(
        db,
        sufijo: 'rechazada',
        estado: EstadoEvidenciaLocal.rechazado,
        motivoRechazo: 'hash no coincide',
      );

      final filasEvidencia = await db.select(db.evidenciaLocal).get();
      expect(filasEvidencia, hasLength(2));

      final pendiente = filasEvidencia.firstWhere(
        (e) => e.uuidCliente == 'evidencia-nueva',
      );
      expect(pendiente.tipo, 'foto_incidencia');
      expect(pendiente.estado, EstadoEvidenciaLocal.pendiente);
      expect(pendiente.motivoRechazo, isNull);

      final rechazada = filasEvidencia.firstWhere(
        (e) => e.uuidCliente == 'evidencia-rechazada',
      );
      expect(rechazada.estado, EstadoEvidenciaLocal.rechazado);
      expect(rechazada.motivoRechazo, 'hash no coincide');
    });
  });
}
