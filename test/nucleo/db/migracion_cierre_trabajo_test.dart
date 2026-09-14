// Prueba de la migración de esquema v6 -> v7 (HU-09: cerrar el trabajo con
// imagen del campo).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. A diferencia de las
// migraciones anteriores (v2->v6, todas `createTable` de una tabla nueva),
// esta es la PRIMERA que hace `ALTER TABLE ADD COLUMN` sobre una tabla
// existente con filas reales (`trabajo_local`, de HU-05) — el riesgo real
// acá es perder o corromper esas filas, no solo "crear la tabla nueva".
//
// Sigue el mismo patrón que `migracion_incidencia_test.dart`: arma a mano,
// con SQL crudo, el esquema v6 completo tal como quedó en dispositivos
// reales (`cola_sync` + las 4 tablas de catálogo de TE-06 +
// `trabajo_local`/`sesion_local` de HU-05, esta última ya con las columnas
// de HU-06/HU-07 + `condicion_local` de HU-06 + `evidencia_local` de TE-07 +
// `incidencia_local` de HU-08), con una fila real preexistente en
// `trabajo_local` (esquema VIEJO, sin las columnas de cierre), fija `PRAGMA
// user_version = 6` y recién ahí abre [AppDatabase] con `schemaVersion = 7`
// sobre el mismo executor — drift detecta el `user_version` viejo y dispara
// `onUpgrade(m, 6, 7)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/trabajo_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v6 real: `cola_sync` de v1 + las 4 tablas de
/// catálogo de TE-06 (v2) + `trabajo_local`/`sesion_local` de HU-05 (v3,
/// `sesion_local` ya con las columnas de HU-06/HU-07 que se agregaron a la
/// creación original de la tabla, no con `ALTER TABLE`) + `condicion_local`
/// de HU-06 (v4) + `evidencia_local` de TE-07 (v5) + `incidencia_local` de
/// HU-08 (v6), tal como quedaron creadas en dispositivos reales.
/// `trabajo_local` acá es DELIBERADAMENTE el esquema VIEJO, sin ninguna de
/// las columnas de cierre que esta migración agrega.
const _createEsquemaV6 = '''
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

CREATE TABLE incidencia_local (
  uuid_cliente TEXT NOT NULL PRIMARY KEY,
  sesion_uuid_cliente TEXT NOT NULL,
  tipo TEXT NOT NULL,
  descripcion TEXT NULL,
  hora INTEGER NOT NULL,
  evidencia_foto_uuid_cliente TEXT NOT NULL
);
''';

Future<void> _insertarTrabajoDePrueba(AppDatabase db, {String sufijo = ''}) {
  return db
      .into(db.trabajoLocal)
      .insert(
        TrabajoLocalCompanion.insert(
          uuidCliente: 'trabajo-$sufijo',
          ordenId: 1,
          loteId: 1,
          nroAplicacion: 1,
          inicio: DateTime.utc(2026, 9, 11, 8),
        ),
      );
}

void main() {
  group('migración de esquema drift (HU-09: cerrar trabajo con imagen)', () {
    test('base nueva sin historial: onCreate deja trabajo_local con las '
        'columnas de cierre, en abierto por default', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await _insertarTrabajoDePrueba(db, sufijo: 'a');
      final trabajo = (await db.select(db.trabajoLocal).get()).single;
      expect(trabajo.uuidCliente, 'trabajo-a');
      expect(trabajo.estado, EstadoTrabajoLocal.abierto);
      expect(trabajo.fin, isNull);
      expect(trabajo.litrosSobrante, isNull);
      expect(trabajo.evidenciaImagenCampoUuidCliente, isNull);
      expect(trabajo.uuidClienteCierre, isNull);

      // Cierre local: actualiza la misma fila, no reescribe la apertura
      // (invariante 6 de CLAUDE.md), mismo criterio que `SesionLocal`.
      await (db.update(
        db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals('trabajo-a'))).write(
        TrabajoLocalCompanion(
          estado: const Value(EstadoTrabajoLocal.cerrado),
          fin: Value(DateTime.utc(2026, 9, 11, 18)),
          litrosSobrante: Value(Decimal.parse('5.25')),
          evidenciaImagenCampoUuidCliente: const Value('evidencia-a'),
          uuidClienteCierre: const Value('cierre-a'),
        ),
      );
      final trabajoCerrado = (await db.select(db.trabajoLocal).get()).single;
      expect(trabajoCerrado.estado, EstadoTrabajoLocal.cerrado);
      // `drift` guarda el instante correctamente pero lo devuelve como
      // `DateTime` local (no UTC) — comparar vía `.toUtc()`, mismo motivo
      // por el que las migraciones anteriores no comparan `DateTime` con
      // `==` directo.
      expect(trabajoCerrado.fin!.toUtc(), DateTime.utc(2026, 9, 11, 18));
      expect(trabajoCerrado.litrosSobrante, Decimal.parse('5.25'));
      expect(trabajoCerrado.evidenciaImagenCampoUuidCliente, 'evidencia-a');
      expect(trabajoCerrado.uuidClienteCierre, 'cierre-a');
      // Los datos de apertura no se tocaron.
      expect(trabajoCerrado.ordenId, 1);
      expect(trabajoCerrado.loteId, 1);
      expect(trabajoCerrado.nroAplicacion, 1);

      // La unicidad de `uuidClienteCierre` la da el índice creado aparte
      // (no una columna UNIQUE, ver el comentario en `trabajo_local.dart`)
      // — un segundo cierre con el mismo uuid_cliente_cierre debe fallar.
      await _insertarTrabajoDePrueba(db, sufijo: 'b');
      expect(
        () =>
            (db.update(
              db.trabajoLocal,
            )..where((t) => t.uuidCliente.equals('trabajo-b'))).write(
              const TrabajoLocalCompanion(uuidClienteCierre: Value('cierre-a')),
            ),
        throwsA(isA<sqlite3.SqliteException>()),
      );
    });

    test('base v6 preexistente con una fila real de trabajo_local (esquema '
        'viejo, sin columnas de cierre) migra a v7 sin perderla ni '
        'duplicarla, y queda con estado=abierto y el resto de columnas '
        'nuevas en null', () async {
      // Arma a mano el estado "v6 preexistente" — el mismo que ya corrió
      // en dispositivos reales — sobre un sqlite3.Database crudo, antes
      // de que drift lo toque.
      final rawDb = sqlite3.sqlite3.openInMemory();
      rawDb.execute(_createEsquemaV6);
      rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v6', 'trabajo', '{"orden_id":1}', 1, 'confirmado', 1700000000);
        ''');
      rawDb.execute('''
          INSERT INTO trabajo_local
            (uuid_cliente, orden_id, lote_id, nro_aplicacion, hectareas_declaradas, inicio)
          VALUES
            ('trabajo-preexistente', 5, 9, 2, '37.40', 1700000000);
        ''');
      rawDb.execute('''
          INSERT INTO sesion_local
            (uuid_cliente, trabajo_uuid_cliente, secuencia, piloto_id, hectareas_declaradas, inicio, estado)
          VALUES
            ('sesion-preexistente', 'trabajo-preexistente', 1, 7, '0', 1700000300, 'abierta');
        ''');
      rawDb.execute('PRAGMA user_version = 6;');

      // Mismo executor, ahora abierto por AppDatabase (schemaVersion 7):
      // drift compara el user_version (6) recién fijado contra
      // schemaVersion y dispara onUpgrade(m, 6, 7) de verdad.
      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(db.close);

      final filasColaSync = await db.select(db.colaSync).get();
      expect(
        filasColaSync,
        hasLength(1),
        reason:
            'la fila sembrada en v6 no debe perderse ni duplicarse al '
            'migrar',
      );
      expect(filasColaSync.single.uuidCliente, 'preexistente-v6');

      final filasSesion = await db.select(db.sesionLocal).get();
      expect(
        filasSesion,
        hasLength(1),
        reason:
            'la sesión ya abierta en v6 no debe perderse ni duplicarse al '
            'migrar',
      );
      expect(filasSesion.single.uuidCliente, 'sesion-preexistente');

      final filasTrabajo = await db.select(db.trabajoLocal).get();
      expect(
        filasTrabajo,
        hasLength(1),
        reason:
            'el trabajo ya abierto en v6 no debe perderse ni duplicarse '
            'al migrar',
      );
      final trabajo = filasTrabajo.single;

      // Los datos de apertura, capturados ANTES de esta migración, tienen
      // que sobrevivir intactos.
      expect(trabajo.uuidCliente, 'trabajo-preexistente');
      expect(trabajo.ordenId, 5);
      expect(trabajo.loteId, 9);
      expect(trabajo.nroAplicacion, 2);
      expect(trabajo.hectareasDeclaradas, Decimal.parse('37.40'));
      expect(
        trabajo.inicio.toUtc(),
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true),
      );

      // Las columnas nuevas de HU-09 quedan con su default/null, nunca
      // con un valor inventado.
      expect(trabajo.estado, EstadoTrabajoLocal.abierto);
      expect(trabajo.fin, isNull);
      expect(trabajo.litrosSobrante, isNull);
      expect(trabajo.evidenciaImagenCampoUuidCliente, isNull);
      expect(trabajo.uuidClienteCierre, isNull);

      // trabajo_local ya existía en v6: la migración no debe haberla
      // recreado como tabla nueva vacía (si lo hiciera, el insert de
      // arriba ya habría fallado con el select en 0 filas en vez de 1).
      // Además, sigue siendo usable para nuevas filas y para el cierre.
      await _insertarTrabajoDePrueba(db, sufijo: 'nuevo');
      await (db.update(
        db.trabajoLocal,
      )..where((t) => t.uuidCliente.equals('trabajo-preexistente'))).write(
        TrabajoLocalCompanion(
          estado: const Value(EstadoTrabajoLocal.cerrado),
          fin: Value(DateTime.utc(2026, 9, 11, 19)),
          evidenciaImagenCampoUuidCliente: const Value('evidencia-cierre'),
          uuidClienteCierre: const Value('cierre-preexistente'),
        ),
      );
      final trabajoCerrado =
          await (db.select(db.trabajoLocal)
                ..where((t) => t.uuidCliente.equals('trabajo-preexistente')))
              .getSingle();
      expect(trabajoCerrado.estado, EstadoTrabajoLocal.cerrado);
      expect(
        trabajoCerrado.evidenciaImagenCampoUuidCliente,
        'evidencia-cierre',
      );
      expect(trabajoCerrado.uuidClienteCierre, 'cierre-preexistente');
    });
  });
}
