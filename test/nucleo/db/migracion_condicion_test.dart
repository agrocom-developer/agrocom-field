// Prueba de la migración de esquema v3 -> v4 (HU-06: condiciones al abrir
// sesión de vuelo).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. Esta prueba ejercita el
// `onUpgrade` real (no lo simula), siguiendo el mismo patrón que
// `migracion_trabajo_sesion_test.dart`: arma a mano, con SQL crudo, el
// esquema v3 completo tal como quedó en dispositivos reales (`cola_sync` +
// las 4 tablas de catálogo de TE-06 + `trabajo_local` + `sesion_local` de
// HU-05, con una fila real preexistente en `cola_sync` y otra en
// `sesion_local`), fija `PRAGMA user_version = 3` y recién ahí abre
// [AppDatabase] con `schemaVersion = 4` sobre el mismo executor — drift
// detecta el `user_version` viejo y dispara `onUpgrade(m, 3, 4)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/db/tablas/sesion_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v3 real: `cola_sync` de v1 + las 4 tablas de
/// catálogo que agregó TE-06 (v2) + `trabajo_local`/`sesion_local` que agregó
/// HU-05 (v3), tal como quedaron creadas en dispositivos reales.
const _createEsquemaV3 = '''
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
''';

Future<void> _insertarCondicionDePrueba(
  AppDatabase db, {
  String sufijo = '',
  String? observacionAgronomo,
  String? firmaObservacion,
}) {
  return db
      .into(db.condicionLocal)
      .insert(
        CondicionLocalCompanion.insert(
          uuidCliente: 'condicion-$sufijo',
          sesionUuidCliente: 'sesion-$sufijo',
          momento: 'inicio_sesion',
          vientoKmh: Decimal.parse('12.50'),
          temperaturaC: Decimal.parse('24.00'),
          humedadPct: Decimal.parse('65.00'),
          observacionAgronomo: Value(observacionAgronomo),
          firmaObservacion: Value(firmaObservacion),
        ),
      );
}

void main() {
  group('migración de esquema drift (HU-06: condiciones al abrir sesión)', () {
    test(
      'base nueva sin historial: onCreate deja condicion_local creada y '
      'usable',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await _insertarCondicionDePrueba(db, sufijo: 'a');
        final condicion = (await db.select(db.condicionLocal).get()).single;
        expect(condicion.uuidCliente, 'condicion-a');
        expect(condicion.sesionUuidCliente, 'sesion-a');
        expect(condicion.momento, 'inicio_sesion');
        expect(condicion.vientoKmh, Decimal.parse('12.50'));
        expect(condicion.temperaturaC, Decimal.parse('24.00'));
        expect(condicion.humedadPct, Decimal.parse('65.00'));
        expect(condicion.observacionAgronomo, isNull);
        expect(condicion.firmaObservacion, isNull);
      },
    );

    test(
      'base v3 preexistente con datos reales en cola_sync y sesion_local '
      'migra a v4 sin perderlos, y condicion_local queda creada y usable',
      () async {
        // Arma a mano el estado "v3 preexistente" — el mismo que ya corrió
        // en dispositivos reales — sobre un sqlite3.Database crudo, antes de
        // que drift lo toque.
        final rawDb = sqlite3.sqlite3.openInMemory();
        rawDb.execute(_createEsquemaV3);
        rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v3', 'sesion', '{"piloto_id":7}', 1, 'confirmado', 1700000000);
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
        rawDb.execute('PRAGMA user_version = 3;');

        // Mismo executor, ahora abierto por AppDatabase (schemaVersion 4):
        // drift compara el user_version (3) recién fijado contra
        // schemaVersion y dispara onUpgrade(m, 3, 4) de verdad.
        final db = AppDatabase(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        final filasColaSync = await db.select(db.colaSync).get();
        expect(
          filasColaSync,
          hasLength(1),
          reason:
              'la fila sembrada en v3 no debe perderse ni duplicarse al migrar',
        );
        final filaPreexistente = filasColaSync.single;
        expect(filaPreexistente.uuidCliente, 'preexistente-v3');
        expect(filaPreexistente.tipoEntidad, 'sesion');
        expect(filaPreexistente.payload, '{"piloto_id":7}');
        expect(filaPreexistente.secuencia, 1);
        expect(filaPreexistente.estado, EstadoSync.confirmado);

        final filasSesion = await db.select(db.sesionLocal).get();
        expect(
          filasSesion,
          hasLength(1),
          reason:
              'la sesión ya abierta en v3 no debe perderse ni duplicarse al '
              'migrar',
        );
        final sesionPreexistente = filasSesion.single;
        expect(sesionPreexistente.uuidCliente, 'sesion-preexistente');
        expect(
          sesionPreexistente.trabajoUuidCliente,
          'trabajo-preexistente',
        );
        expect(sesionPreexistente.secuencia, 1);
        expect(sesionPreexistente.pilotoId, 7);
        expect(sesionPreexistente.hectareasDeclaradas, Decimal.parse('0'));
        expect(sesionPreexistente.estado, EstadoSesionLocal.abierta);
        expect(sesionPreexistente.fin, isNull);

        // condicion_local no existía en v3: si onUpgrade no la creó, estos
        // insert+select fallarían con "no such table".
        await _insertarCondicionDePrueba(db, sufijo: 'sesion-preexistente');
        await _insertarCondicionDePrueba(
          db,
          sufijo: 'con-observacion',
          observacionAgronomo: 'Viento por encima del umbral, se autoriza.',
          firmaObservacion: 'Ing. Agr. Juana Pérez',
        );

        final filasCondicion = await db.select(db.condicionLocal).get();
        expect(filasCondicion, hasLength(2));

        final sinObservacion = filasCondicion.firstWhere(
          (c) => c.uuidCliente == 'condicion-sesion-preexistente',
        );
        expect(sinObservacion.sesionUuidCliente, 'sesion-sesion-preexistente');
        expect(sinObservacion.momento, 'inicio_sesion');
        expect(sinObservacion.vientoKmh, Decimal.parse('12.50'));
        expect(sinObservacion.temperaturaC, Decimal.parse('24.00'));
        expect(sinObservacion.humedadPct, Decimal.parse('65.00'));
        expect(sinObservacion.observacionAgronomo, isNull);
        expect(sinObservacion.firmaObservacion, isNull);

        final conObservacion = filasCondicion.firstWhere(
          (c) => c.uuidCliente == 'condicion-con-observacion',
        );
        expect(
          conObservacion.observacionAgronomo,
          'Viento por encima del umbral, se autoriza.',
        );
        expect(conObservacion.firmaObservacion, 'Ing. Agr. Juana Pérez');
      },
    );
  });
}
