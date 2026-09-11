import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../tipos/decimal_drift_converter.dart';
import 'tablas/cola_sync.dart';
import 'tablas/cursor_catalogo.dart';
import 'tablas/lote_catalogo.dart';
import 'tablas/orden_catalogo.dart';
import 'tablas/persona_catalogo.dart';

part 'database.g.dart';

/// Base local SQLite (invariante 1 de CLAUDE.md: la UI nunca lee de la red
/// directo, siempre de acá). Versión 1 solo traía el outbox ([ColaSync]);
/// TE-06 agrega las tablas espejo de catálogo (solo lectura, PK = id de
/// servidor, sin `uuid_cliente`) y su cursor de pull. Las tablas espejo de
/// cada feature de escritura (trabajos, sesiones, recargas, incidencias...)
/// se agregan en tareas técnicas posteriores, cada una subiendo
/// [schemaVersion] con su propia migración — nunca reescribiendo la
/// anterior, para no perder datos ya capturados en dispositivos reales.
@DriftDatabase(
  tables: [
    ColaSync,
    OrdenCatalogo,
    LoteCatalogo,
    PersonaCatalogo,
    CursorCatalogo,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? implementation])
    : super(implementation ?? driftDatabase(name: 'agrocom_field'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 solo tenía `cola_sync`, ya creada en dispositivos reales — no se
      // toca. v2 agrega las tablas de catálogo (TE-06) sin tocar la anterior.
      if (from < 2) {
        await m.createTable(ordenCatalogo);
        await m.createTable(loteCatalogo);
        await m.createTable(personaCatalogo);
        await m.createTable(cursorCatalogo);
      }
    },
  );
}
