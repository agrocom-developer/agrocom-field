// Prueba de la migración de esquema v2 -> v3 (HU-05, esqueleto vertical:
// abrir trabajo -> abrir sesión -> cerrar sesión).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. Esta prueba ejercita el
// `onUpgrade` real (no lo simula), siguiendo el mismo patrón que
// `migracion_catalogo_test.dart`: arma a mano, con SQL crudo, el esquema v2
// completo tal como quedó en dispositivos reales (`cola_sync` + las 4 tablas
// de catálogo de TE-06, con una fila real preexistente en `cola_sync`), fija
// `PRAGMA user_version = 2` y recién ahí abre [AppDatabase] con
// `schemaVersion = 3` sobre el mismo executor — drift detecta el
// `user_version` viejo y dispara `onUpgrade(m, 2, 3)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/db/tablas/sesion_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al esquema v2 real (ver `migracion_catalogo_test.dart`
/// para el detalle de cada tabla): `cola_sync` de v1 más las 4 tablas de
/// catálogo que agregó TE-06, tal como quedaron creadas en dispositivos
/// reales.
const _createEsquemaV2 = '''
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

Future<void> _insertarSesionDePrueba(AppDatabase db, {String sufijo = ''}) {
  return db
      .into(db.sesionLocal)
      .insert(
        SesionLocalCompanion.insert(
          uuidCliente: 'sesion-$sufijo',
          trabajoUuidCliente: 'trabajo-$sufijo',
          secuencia: 1,
          pilotoId: 7,
          inicio: DateTime.utc(2026, 9, 11, 8, 5),
        ),
      );
}

void main() {
  group('migración de esquema drift (HU-05: trabajo y sesión local)', () {
    test('base nueva sin historial: onCreate deja trabajo_local y sesion_local '
        'creadas y usables', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await _insertarTrabajoDePrueba(db, sufijo: 'a');
      final trabajo = (await db.select(db.trabajoLocal).get()).single;
      expect(trabajo.uuidCliente, 'trabajo-a');
      expect(trabajo.ordenId, 1);
      expect(trabajo.loteId, 1);
      expect(trabajo.nroAplicacion, 1);
      expect(trabajo.hectareasDeclaradas, Decimal.parse('0'));

      await _insertarSesionDePrueba(db, sufijo: 'a');
      final sesion = (await db.select(db.sesionLocal).get()).single;
      expect(sesion.uuidCliente, 'sesion-a');
      expect(sesion.trabajoUuidCliente, 'trabajo-a');
      expect(sesion.secuencia, 1);
      expect(sesion.pilotoId, 7);
      expect(sesion.auxiliarId, isNull);
      expect(sesion.dronId, isNull);
      expect(sesion.hectareasDeclaradas, Decimal.parse('0'));
      expect(sesion.hectareaInicialAcumulada, isNull);
      expect(sesion.estado, EstadoSesionLocal.abierta);
      expect(sesion.fin, isNull);
      expect(sesion.motivoCierre, isNull);
      expect(sesion.hectareasDeclaradasCierre, isNull);
      expect(sesion.litrosConsumidos, isNull);
      expect(sesion.uuidClienteCierre, isNull);

      // Cierre local: actualiza la misma fila, no reescribe la apertura.
      await (db.update(
        db.sesionLocal,
      )..where((t) => t.uuidCliente.equals('sesion-a'))).write(
        SesionLocalCompanion(
          estado: const Value(EstadoSesionLocal.cerrada),
          fin: Value(DateTime.utc(2026, 9, 11, 10)),
          motivoCierre: const Value('completado'),
          hectareasDeclaradasCierre: Value(Decimal.parse('12.5')),
          litrosConsumidos: Value(Decimal.parse('340.2')),
          uuidClienteCierre: const Value('cierre-a'),
        ),
      );
      final sesionCerrada = (await db.select(db.sesionLocal).get()).single;
      expect(sesionCerrada.estado, EstadoSesionLocal.cerrada);
      expect(sesionCerrada.motivoCierre, 'completado');
      expect(sesionCerrada.hectareasDeclaradasCierre, Decimal.parse('12.5'));
      // La hectárea de apertura sigue siendo la original, no la de cierre.
      expect(sesionCerrada.hectareasDeclaradas, Decimal.parse('0'));
      expect(sesionCerrada.uuidClienteCierre, 'cierre-a');
    });

    test(
      'base v2 preexistente con datos reales en cola_sync migra a v3 sin '
      'perderlos, y trabajo_local/sesion_local quedan creadas y usables',
      () async {
        // Arma a mano el estado "v2 preexistente" — el mismo que ya corrió
        // en dispositivos reales — sobre un sqlite3.Database crudo, antes de
        // que drift lo toque.
        final rawDb = sqlite3.sqlite3.openInMemory();
        rawDb.execute(_createEsquemaV2);
        rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v2', 'trabajo', '{"orden_id":1}', 1, 'confirmado', 1700000000);
        ''');
        rawDb.execute('''
          INSERT INTO orden_catalogo
            (id, contrato_id, lote_id, nro_aplicacion, litros_ha, fecha_emision, estado, updated_at)
          VALUES
            (1, 10, 20, 1, '15.5', '2026-08-26', 'vigente', 1756209600000);
        ''');
        rawDb.execute('PRAGMA user_version = 2;');

        // Mismo executor, ahora abierto por AppDatabase (schemaVersion 3):
        // drift compara el user_version (2) recién fijado contra
        // schemaVersion y dispara onUpgrade(m, 2, 3) de verdad.
        final db = AppDatabase(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        final filasColaSync = await db.select(db.colaSync).get();
        expect(
          filasColaSync,
          hasLength(1),
          reason:
              'la fila sembrada en v2 no debe perderse ni duplicarse al migrar',
        );
        final filaPreexistente = filasColaSync.single;
        expect(filaPreexistente.uuidCliente, 'preexistente-v2');
        expect(filaPreexistente.tipoEntidad, 'trabajo');
        expect(filaPreexistente.payload, '{"orden_id":1}');
        expect(filaPreexistente.secuencia, 1);
        expect(filaPreexistente.estado, EstadoSync.confirmado);

        // `AppDatabase.schemaVersion` avanza con el tiempo (hoy 8, no 3):
        // esta prueba, al abrir con la clase real, migra de punta a punta
        // hasta la versión actual, no solo hasta v3. TE-20 (v8) recrea
        // `orden_catalogo` entera (contrato de servidor incompatible,
        // `lote_id` único → `lotes[]`) — la fila sembrada en v2, con el
        // esquema VIEJO, se pierde a propósito ahí (ver el comentario de
        // esa migración en `database.dart`): es un espejo de solo lectura,
        // nunca datos capturados sin conectividad, así que no aplica la
        // misma garantía que protege a `cola_sync`/`trabajo_local` arriba.
        expect(await db.select(db.ordenCatalogo).get(), isEmpty);
        // La tabla sigue creada y usable con el esquema nuevo.
        await db
            .into(db.ordenCatalogo)
            .insert(
              OrdenCatalogoCompanion.insert(
                id: const Value(2),
                contratoId: 10,
                loteId: 20,
                nroAplicacion: 1,
                litrosHa: Value(Decimal.parse('15.5')),
                fechaEmision: '2026-08-26',
                estado: 'vigente',
                updatedAt: DateTime.utc(2026, 8, 26),
              ),
            );
        expect(
          (await db.select(db.ordenCatalogo).get()).single.litrosHa,
          Decimal.parse('15.5'),
        );

        // trabajo_local/sesion_local no existían en v2: si onUpgrade no las
        // creó, estos insert+select fallarían con "no such table".
        await _insertarTrabajoDePrueba(db, sufijo: 'b');
        await _insertarSesionDePrueba(db, sufijo: 'b');

        expect(
          (await db.select(db.trabajoLocal).get()).single.uuidCliente,
          'trabajo-b',
        );
        final sesion = (await db.select(db.sesionLocal).get()).single;
        expect(sesion.uuidCliente, 'sesion-b');
        expect(sesion.trabajoUuidCliente, 'trabajo-b');
        expect(sesion.estado, EstadoSesionLocal.abierta);
      },
    );
  });
}
