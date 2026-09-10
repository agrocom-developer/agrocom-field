import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tablas/cola_sync.dart';

part 'database.g.dart';

/// Base local SQLite (invariante 1 de CLAUDE.md: la UI nunca lee de la red
/// directo, siempre de acá). Este esqueleto solo trae el outbox
/// ([ColaSync]); las tablas espejo de cada feature (trabajos, sesiones,
/// recargas, incidencias...) se agregan en tareas técnicas posteriores
/// (TE-04 propiamente dicho), cada una subiendo [schemaVersion] con su
/// propia migración — nunca reescribiendo la anterior.
@DriftDatabase(tables: [ColaSync])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? implementation])
    : super(implementation ?? driftDatabase(name: 'agrocom_field'));

  @override
  int get schemaVersion => 1;
}
