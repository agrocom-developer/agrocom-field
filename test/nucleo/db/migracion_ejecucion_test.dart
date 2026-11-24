// Migración de esquema v14 -> v15 (ADR 0016): agrega `servicio_adjudicado`,
// `registro_ejecucion` y `foto_ejecucion` solo con `CREATE TABLE`. Lo
// capturado sin señal en versiones anteriores (outbox, trabajos, sesiones,
// evidencias) queda intacto: una migración que lo perdiera lo perdería sin
// forma de recuperarlo.
//
// Se parte de una base real en v14: se crea el esquema actual con
// [AppDatabase], se quitan las tres tablas nuevas y se fija
// `PRAGMA user_version = 14`. Después se vuelve a abrir con el
// `schemaVersion` real para que corra `onUpgrade`.

import 'dart:io';

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/registro_ejecucion.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File archivo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('migracion_v15');
    archivo = File('${dir.path}/agrocom.sqlite');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('v14 -> v15 crea las tablas nuevas y conserva lo capturado', () async {
    // 1. Una base en v14 con un registro pendiente en el outbox.
    final v14 = AppDatabase(NativeDatabase(archivo));
    await v14.customStatement('SELECT 1'); // fuerza la creación
    await v14
        .into(v14.colaSync)
        .insert(
          ColaSyncCompanion.insert(
            uuidCliente: 'pendiente-1',
            tipoEntidad: 'trabajo',
            payload: '{"orden_id":1}',
            secuencia: 7,
          ),
        );
    await v14.customStatement('DROP TABLE servicio_adjudicado');
    await v14.customStatement('DROP TABLE registro_ejecucion');
    await v14.customStatement('DROP TABLE foto_ejecucion');
    await v14.customStatement('PRAGMA user_version = 14');
    await v14.close();

    // 2. Se abre con el esquema real: corre `onUpgrade`.
    final v15 = AppDatabase(NativeDatabase(archivo));
    addTearDown(v15.close);
    expect(v15.schemaVersion, 15);

    final tablas =
        (await v15
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table'",
                )
                .get())
            .map((f) => f.read<String>('name'))
            .toSet();
    expect(
      tablas,
      containsAll([
        'servicio_adjudicado',
        'registro_ejecucion',
        'foto_ejecucion',
      ]),
    );

    // 3. Nada de lo anterior se perdió.
    final cola = await v15.select(v15.colaSync).get();
    expect(cola.single.uuidCliente, 'pendiente-1');
    expect(cola.single.secuencia, 7);
    expect(cola.single.payload, '{"orden_id":1}');

    // 4. Y las tablas nuevas funcionan.
    await v15
        .into(v15.registroEjecucion)
        .insert(
          RegistroEjecucionCompanion.insert(
            uuidCliente: 'r1',
            solicitudId: 10,
            tipo: 'inicio',
            payload: '{}',
            secuencia: 1,
          ),
        );
    expect(
      (await v15.select(v15.registroEjecucion).getSingle()).estado,
      EstadoRegistroEjecucion.pendiente,
    );
  });

  test('una instalación nueva crea todo el esquema v15', () async {
    final db = AppDatabase(NativeDatabase(archivo));
    addTearDown(db.close);
    expect(await db.select(db.servicioAdjudicado).get(), isEmpty);
    expect(await db.select(db.registroEjecucion).get(), isEmpty);
    expect(await db.select(db.fotoEjecucion).get(), isEmpty);
  });
}
