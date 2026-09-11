// Prueba de la migración de esquema v1 -> v2 (TE-06, pull de catálogo).
//
// El esquema de `drift` y sus migraciones locales son, junto al motor de
// sync, lo que CLAUDE.md marca como "qué no delegar sin revisión línea por
// línea": una migración mal escrita pierde datos de campo capturados sin
// conectividad, sin forma de recuperarlos después. Esta prueba ejercita el
// `onUpgrade` real (no lo simula): arma a mano, con SQL crudo, el esquema
// v1 tal como quedó en dispositivos reales (solo `cola_sync`, con una fila
// de datos real), fija `PRAGMA user_version = 1` y recién ahí abre
// [AppDatabase] con `schemaVersion = 2` sobre el mismo executor — drift
// detecta el `user_version` viejo y dispara `onUpgrade(m, 1, 2)` de verdad.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQL equivalente al `CREATE TABLE cola_sync` real de v1 (ver
/// `lib/nucleo/db/tablas/cola_sync.dart` y el `$ColaSyncTable` generado):
/// misma forma de columnas, para que la migración v1 -> v2 parta de un
/// esquema realista y no de una versión simplificada a mano.
const _createColaSyncV1 = '''
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
''';

Future<void> _insertarOrdenDePrueba(AppDatabase db) async {
  await db
      .into(db.ordenCatalogo)
      .insert(
        OrdenCatalogoCompanion.insert(
          id: const Value(1),
          contratoId: 10,
          loteId: 20,
          nroAplicacion: 1,
          litrosHa: Decimal.parse('15.5'),
          fechaEmision: '2026-08-26',
          estado: 'vigente',
          updatedAt: DateTime.utc(2026, 8, 26, 12),
        ),
      );
}

Future<void> _insertarLoteDePrueba(AppDatabase db) async {
  await db
      .into(db.loteCatalogo)
      .insert(
        LoteCatalogoCompanion.insert(
          id: const Value(1),
          campoId: 5,
          codigo: 'L-1',
          hectareas: Decimal.parse('120.75'),
          updatedAt: DateTime.utc(2026, 8, 26, 12),
        ),
      );
}

Future<void> _insertarPersonaDePrueba(AppDatabase db) async {
  await db
      .into(db.personaCatalogo)
      .insert(
        PersonaCatalogoCompanion.insert(
          id: const Value(1),
          nombre: 'Juana Pérez',
          rol: 'piloto',
          activo: true,
          updatedAt: DateTime.utc(2026, 8, 26, 12),
        ),
      );
}

Future<void> _insertarCursorDePrueba(AppDatabase db) async {
  // `id: Value(0)` explícito a propósito: ver el comentario en
  // `cursor_catalogo.dart` sobre por qué omitir la columna no alcanza aunque
  // tenga `withDefault(0)` (SQLite la trata como alias de rowid).
  await db
      .into(db.cursorCatalogo)
      .insertOnConflictUpdate(
        const CursorCatalogoCompanion(id: Value(0), cursor: Value('abc')),
      );
}

void main() {
  group('migración de esquema drift (TE-06: catálogo con cursor)', () {
    test(
      'base nueva sin historial: onCreate deja las 5 tablas creadas y usables',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await db
            .into(db.colaSync)
            .insert(
              ColaSyncCompanion.insert(
                uuidCliente: 'u1',
                tipoEntidad: 'trabajo',
                payload: '{}',
                secuencia: 1,
              ),
            );
        expect(await db.select(db.colaSync).get(), hasLength(1));

        await _insertarOrdenDePrueba(db);
        await _insertarLoteDePrueba(db);
        await _insertarPersonaDePrueba(db);
        await _insertarCursorDePrueba(db);

        final orden = (await db.select(db.ordenCatalogo).get()).single;
        expect(orden.litrosHa, Decimal.parse('15.5'));
        expect(orden.humedadMinPct, isNull);

        final lote = (await db.select(db.loteCatalogo).get()).single;
        expect(lote.hectareas, Decimal.parse('120.75'));

        final persona = (await db.select(db.personaCatalogo).get()).single;
        expect(persona.nombre, 'Juana Pérez');
        expect(persona.activo, isTrue);

        final cursor = (await db.select(db.cursorCatalogo).get()).single;
        expect(cursor.id, 0);
        expect(cursor.cursor, 'abc');
      },
    );

    test(
      'base v1 preexistente con datos reales en cola_sync migra a v2 sin '
      'perderlos, y las 4 tablas de catálogo quedan creadas y usables',
      () async {
        // Arma a mano el estado "v1 preexistente" — el mismo que ya corrió en
        // dispositivos reales — sobre un sqlite3.Database crudo, antes de que
        // drift lo toque.
        final rawDb = sqlite3.sqlite3.openInMemory();
        rawDb.execute(_createColaSyncV1);
        rawDb.execute('''
          INSERT INTO cola_sync
            (uuid_cliente, tipo_entidad, payload, secuencia, estado, creado_en)
          VALUES
            ('preexistente-v1', 'trabajo', '{"orden_id":1}', 1, 'confirmado', 1700000000);
        ''');
        rawDb.execute('PRAGMA user_version = 1;');

        // Mismo executor, ahora abierto por AppDatabase (schemaVersion 2):
        // drift compara el user_version (1) recién fijado contra
        // schemaVersion y dispara onUpgrade(m, 1, 2) de verdad.
        final db = AppDatabase(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        final filasColaSync = await db.select(db.colaSync).get();
        expect(
          filasColaSync,
          hasLength(1),
          reason:
              'la fila sembrada en v1 no debe perderse ni duplicarse al migrar',
        );
        final filaPreexistente = filasColaSync.single;
        expect(filaPreexistente.uuidCliente, 'preexistente-v1');
        expect(filaPreexistente.tipoEntidad, 'trabajo');
        expect(filaPreexistente.payload, '{"orden_id":1}');
        expect(filaPreexistente.secuencia, 1);
        expect(filaPreexistente.estado, EstadoSync.confirmado);

        // Las 4 tablas de catálogo no existían en v1: si onUpgrade no las
        // creó, estos insert+select fallarían con "no such table".
        await _insertarOrdenDePrueba(db);
        await _insertarLoteDePrueba(db);
        await _insertarPersonaDePrueba(db);
        await _insertarCursorDePrueba(db);

        expect(
          (await db.select(db.ordenCatalogo).get()).single.litrosHa,
          Decimal.parse('15.5'),
        );
        expect(
          (await db.select(db.loteCatalogo).get()).single.hectareas,
          Decimal.parse('120.75'),
        );
        expect(
          (await db.select(db.personaCatalogo).get()).single.nombre,
          'Juana Pérez',
        );
        expect((await db.select(db.cursorCatalogo).get()).single.cursor, 'abc');
      },
    );
  });
}
