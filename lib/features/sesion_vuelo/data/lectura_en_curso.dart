import 'package:drift/drift.dart';

import '../../../nucleo/db/database.dart';
import '../domain/trabajo_en_curso.dart';

/// Lo que este dispositivo tiene en curso (tareas 27 y 28): la sesión
/// abierta o, si no hay ninguna, el trabajo abierto; `null` si no hay nada.
/// Una sola consulta para «Inicio», el detalle de orden y la defensa de
/// `TrabajoRepository`, para que los tres entiendan lo mismo por «en
/// curso».
///
/// Sale de `SesionLocal`/`TrabajoLocal` — no de `TrabajoCatalogo` —, así
/// que aparece aunque el trabajo esté retirado o lo haya abierto la app.
///
/// Desde la tarea 28 la app no abre un segundo trabajo, pero un dispositivo
/// actualizado puede traer más de uno abierto de antes. Entre varios,
/// devuelve el más reciente por `ColaSync.secuencia`, el orden causal global
/// del dispositivo (invariante 5, nunca el reloj): primero una sesión
/// abierta; para un trabajo, la secuencia mayor entre su apertura y las de
/// sus sesiones. Un trabajo asignado sin sesiones no encoló nada (la
/// apertura es del panel) y queda detrás, por orden de inserción local
/// (`rowid`).
class LecturaEnCurso {
  LecturaEnCurso(this._db);

  final AppDatabase _db;

  Stream<TrabajoEnCurso?> observar() => _consulta().watch().map(_desdeFilas);

  /// Lectura puntual: la usa `TrabajoRepository` dentro de su transacción,
  /// antes de escribir.
  Future<TrabajoEnCurso?> leer() async => _desdeFilas(await _consulta().get());

  // `ORDER BY` afuera de la unión: en SQLite el de un `UNION ALL` solo
  // acepta columnas, no expresiones como `orden IS NULL`.
  Selectable<QueryRow> _consulta() => _db.customSelect(
    '''
      SELECT e.trabajo_uuid, e.sesion_uuid,
             COALESCE(e.sesion_inicio, t.inicio) AS inicio,
             l.codigo AS lote_codigo, tc.motivo_retiro
      FROM (
        SELECT * FROM (
          SELECT 1 AS prioridad, s.trabajo_uuid_cliente AS trabajo_uuid,
                 s.uuid_cliente AS sesion_uuid, s.inicio AS sesion_inicio,
                 (SELECT c.secuencia FROM cola_sync c
                   WHERE c.uuid_cliente = s.uuid_cliente) AS orden,
                 s.rowid AS desempate
          FROM sesion_local s
          WHERE s.estado = 'abierta'
          UNION ALL
          SELECT 0, tl.uuid_cliente, NULL, NULL,
                 (SELECT MAX(c.secuencia) FROM cola_sync c
                   WHERE c.uuid_cliente = tl.uuid_cliente
                      OR c.uuid_cliente IN (
                        SELECT s2.uuid_cliente FROM sesion_local s2
                        WHERE s2.trabajo_uuid_cliente = tl.uuid_cliente)),
                 tl.rowid
          FROM trabajo_local tl
          WHERE tl.estado = 'abierto'
        )
        ORDER BY prioridad DESC, orden IS NULL, orden DESC, desempate DESC
        LIMIT 1
      ) e
      LEFT JOIN trabajo_local t ON t.uuid_cliente = e.trabajo_uuid
      LEFT JOIN trabajo_catalogo tc ON tc.uuid_cliente = e.trabajo_uuid
      LEFT JOIN lote_catalogo l ON l.id = COALESCE(t.lote_id, tc.lote_id)
      ''',
    readsFrom: {
      _db.sesionLocal,
      _db.trabajoLocal,
      _db.colaSync,
      _db.trabajoCatalogo,
      _db.loteCatalogo,
    },
  );

  static TrabajoEnCurso? _desdeFilas(List<QueryRow> filas) {
    if (filas.isEmpty) return null;
    final fila = filas.single;
    return TrabajoEnCurso(
      trabajoUuidCliente: fila.read<String>('trabajo_uuid'),
      sesionUuidCliente: fila.readNullable<String>('sesion_uuid'),
      inicio: fila.read<DateTime>('inicio'),
      loteCodigo: fila.readNullable<String>('lote_codigo'),
      motivoRetiro: fila.readNullable<String>('motivo_retiro'),
    );
  }
}
