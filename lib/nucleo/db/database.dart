import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../tipos/decimal_drift_converter.dart';
import 'tablas/cola_sync.dart';
import 'tablas/condicion_local.dart';
import 'tablas/cursor_catalogo.dart';
import 'tablas/lote_catalogo.dart';
import 'tablas/orden_catalogo.dart';
import 'tablas/persona_catalogo.dart';
import 'tablas/sesion_local.dart';
import 'tablas/trabajo_local.dart';

part 'database.g.dart';

/// Base local SQLite (invariante 1 de CLAUDE.md: la UI nunca lee de la red
/// directo, siempre de acá). Versión 1 solo traía el outbox ([ColaSync]);
/// TE-06 (v2) agrega las tablas espejo de catálogo (solo lectura, PK = id de
/// servidor, sin `uuid_cliente`) y su cursor de pull; HU-05 (v3) agrega las
/// primeras tablas espejo de escritura ([TrabajoLocal], [SesionLocal]), con
/// `uuid_cliente` generado en el dispositivo como identidad; HU-06 (v4)
/// agrega [CondicionLocal], las condiciones climáticas capturadas al abrir
/// una sesión. Las tablas espejo del resto de las features de escritura
/// (recargas, incidencias...) se agregan en tareas técnicas posteriores,
/// cada una subiendo [schemaVersion] con su propia migración — nunca
/// reescribiendo la anterior, para no perder datos ya capturados en
/// dispositivos reales.
@DriftDatabase(
  tables: [
    ColaSync,
    OrdenCatalogo,
    LoteCatalogo,
    PersonaCatalogo,
    CursorCatalogo,
    TrabajoLocal,
    SesionLocal,
    CondicionLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? implementation])
    : super(implementation ?? driftDatabase(name: 'agrocom_field'));

  @override
  int get schemaVersion => 4;

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
      // v3 agrega las tablas espejo de trabajo y sesión (HU-05), sin tocar
      // ninguna de las anteriores.
      if (from < 3) {
        await m.createTable(trabajoLocal);
        await m.createTable(sesionLocal);
      }
      // v4 agrega la tabla espejo de condiciones (HU-06), sin tocar ninguna
      // de las anteriores.
      if (from < 4) {
        await m.createTable(condicionLocal);
      }
    },
  );
}
