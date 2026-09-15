import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../tipos/decimal_drift_converter.dart';
import 'tablas/cola_sync.dart';
import 'tablas/condicion_local.dart';
import 'tablas/cursor_catalogo.dart';
import 'tablas/evidencia_local.dart';
import 'tablas/incidencia_local.dart';
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
/// una sesión; TE-07 (v5) agrega [EvidenciaLocal], la cola de evidencias
/// (fotos/capturas comprimidas), SEPARADA de [ColaSync] por invariante 8 de
/// CLAUDE.md; HU-08 (v6) agrega [IncidenciaLocal], el evento puntual que el
/// piloto registra durante una sesión activa, siempre con foto obligatoria;
/// HU-09 (v7) agrega a [TrabajoLocal] las columnas de cierre de trabajo
/// (`estado`, `fin`, `litrosSobrante`, `evidenciaImagenCampoUuidCliente`,
/// `uuidClienteCierre`) con `ALTER TABLE` — primera migración de este
/// esquema que agrega columnas a una tabla existente en vez de crear una
/// tabla nueva. TE-20 (v8) recrea [OrdenCatalogo]: `litrosHa` pasa a
/// nullable y se agrega `kilosPorVuelo` (HU-79 de `agrocom-api`, mutuamente
/// excluyentes) — a diferencia de v7, acá SÍ se recrea la tabla entera en
/// vez de `ALTER TABLE`, porque es un espejo de solo lectura (nunca pierde
/// datos capturados sin conectividad, invariante que protege a
/// `TrabajoLocal`/`SesionLocal`, no a este catálogo) y SQLite no permite
/// aflojar una columna `NOT NULL` con `ALTER TABLE`.
/// Las tablas espejo del resto de las features de escritura (recargas...)
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
    TrabajoLocal,
    SesionLocal,
    CondicionLocal,
    EvidenciaLocal,
    IncidenciaLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? implementation])
    : super(implementation ?? driftDatabase(name: 'agrocom_field'));

  @override
  int get schemaVersion => 8;

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
      // v5 agrega la cola de evidencias (TE-07), sin tocar ninguna de las
      // anteriores.
      if (from < 5) {
        await m.createTable(evidenciaLocal);
      }
      // v6 agrega la tabla espejo de incidencias (HU-08), sin tocar
      // ninguna de las anteriores.
      if (from < 6) {
        await m.createTable(incidenciaLocal);
      }
      // v7 agrega el cierre de trabajo (HU-09) a `trabajo_local` existente,
      // vía `ALTER TABLE` — sin recrear la tabla, que ya tiene filas reales
      // en dispositivos. `uuidClienteCierre` no lleva `UNIQUE` en la
      // definición de columna (SQLite rechaza agregar una columna UNIQUE
      // con ALTER TABLE ADD COLUMN); la unicidad se agrega aparte con
      // `idxTrabajoLocalUuidClienteCierre`.
      //
      // `from >= 3` es a propósito, no solo `from < 7`: si el dispositivo
      // viene de antes de v3, el bloque de arriba (`from < 3`) recién creó
      // `trabajo_local` con `createTable` usando la clase Dart ACTUAL —que
      // ya incluye estas columnas—, así que agregarlas de nuevo acá
      // fallaría con "duplicate column name". Solo hace falta el
      // `ALTER TABLE` cuando la tabla ya existía con el esquema viejo.
      if (from >= 3 && from < 7) {
        await m.addColumn(trabajoLocal, trabajoLocal.estado);
        await m.addColumn(trabajoLocal, trabajoLocal.fin);
        await m.addColumn(trabajoLocal, trabajoLocal.litrosSobrante);
        await m.addColumn(
          trabajoLocal,
          trabajoLocal.evidenciaImagenCampoUuidCliente,
        );
        await m.addColumn(trabajoLocal, trabajoLocal.uuidClienteCierre);
      }
      // El índice, en cambio, hace falta siempre que `from < 7`: si
      // `trabajo_local` se acaba de crear entera arriba (`from < 3`),
      // `createTable` no crea los índices asociados — hay que pedirlo
      // aparte, a diferencia de las columnas (que sí vienen incluidas en el
      // `CREATE TABLE` porque son parte de la clase Dart actual).
      if (from < 7) {
        await m.createIndex(idxTrabajoLocalUuidClienteCierre);
      }
      // v8 (TE-20): `orden_catalogo` es un espejo de solo lectura de
      // `GET /api/sync/catalogo` — a diferencia de `trabajo_local` (v7,
      // arriba), acá no hay ninguna fila que preserve algo capturado sin
      // conectividad, así que recrearla entera es seguro (el próximo pull
      // la vuelve a poblar). Se resetea también `cursor_catalogo`: el
      // cursor es un único valor opaco que combina las cuatro secciones
      // (`ordenes`/`lotes`/`personas`/`trabajos`), así que no se puede
      // "retroceder" solo la parte de órdenes — un pull completo de las
      // cuatro es el único camino correcto y ya es el comportamiento normal
      // de una primera sincronización (`desde` vacío).
      if (from < 8) {
        await m.deleteTable(ordenCatalogo.actualTableName);
        await m.createTable(ordenCatalogo);
        await (delete(cursorCatalogo)).go();
      }
    },
  );
}
