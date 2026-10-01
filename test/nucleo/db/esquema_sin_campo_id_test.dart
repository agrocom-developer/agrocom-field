// Guarda de TE-21 (ADR 0020 de `agrocom-api`): el servidor eliminó la
// entidad `Campo` — `Lote` cuelga directo de `Propiedad` — y la migración v9
// renombró `lote_catalogo.campo_id` a `propiedad_id`. Este test falla si el
// esquema ACTUAL de [AppDatabase] vuelve a declarar una columna `campo_id` en
// cualquier tabla, sea por una tabla nueva copiada de un contrato viejo o por
// revertir el rename.
//
// Revisa dos cosas: lo que declara el código (`allTables`/`$columns`) y lo
// que de verdad crea SQLite al abrir una base nueva (`PRAGMA table_info`), por
// si alguna columna llegara por `customStatement` en vez de por una tabla
// drift. Las fixtures de migración vieja (`campo_id` en el DDL a mano de
// `migracion_*_test.dart`) son legítimas y no pasan por acá: este test solo
// mira el esquema actual.

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('ninguna tabla declarada en AppDatabase tiene una columna campo_id', () {
    final conCampoId = [
      for (final tabla in db.allTables)
        for (final columna in tabla.$columns)
          if (columna.name == 'campo_id') '${tabla.actualTableName}.campo_id',
    ];

    expect(db.allTables, isNotEmpty);
    expect(conCampoId, isEmpty);
  });

  test(
    'la base SQLite creada por AppDatabase no tiene ninguna columna campo_id',
    () async {
      final tablas = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((fila) => fila.read<String>('name'))
          .get();

      final conCampoId = <String>[];
      for (final tabla in tablas) {
        final columnas = await db
            .customSelect("SELECT name FROM pragma_table_info('$tabla')")
            .map((fila) => fila.read<String>('name'))
            .get();
        if (columnas.contains('campo_id')) conCampoId.add(tabla);
      }

      expect(tablas, contains('lote_catalogo'));
      expect(conCampoId, isEmpty);
    },
  );

  test('lote_catalogo ya tiene propiedad_id (rename de la migración v9)', () {
    expect(
      db.loteCatalogo.$columns.map((c) => c.name),
      contains('propiedad_id'),
    );
  });
}
