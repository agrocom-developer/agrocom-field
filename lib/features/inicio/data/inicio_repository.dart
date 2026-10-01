import 'package:drift/drift.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/trabajo_local.dart' show EstadoTrabajoLocal;
import '../domain/trabajo_asignado.dart';
import '../domain/trabajo_en_curso.dart';

/// Repositorio de lectura de la pantalla «Inicio» del piloto (HU-70) —
/// nunca escribe: arma el `Stream` reactivo del trabajo asignado sobre
/// `drift` (invariante 1 de CLAUDE.md, la UI nunca lee de la red).
///
/// **Regla de «el trabajo asignado»** (la HU habla de uno): de los trabajos
/// de `TrabajoCatalogo` que este dispositivo no cerró todavía (sin fila en
/// `TrabajoLocal` con el mismo `uuid_cliente` en estado `cerrado`), el más
/// reciente por `updated_at` del servidor; a igual `updated_at`, el de `id`
/// mayor, para que la elección sea estable. Comparar `updated_at` acá es
/// legítimo: los dos valores los puso el mismo reloj, el del servidor
/// (invariante 5 prohíbe comparar relojes de dispositivos, no esto).
class InicioRepository {
  InicioRepository(this._db);

  final AppDatabase _db;

  Stream<TrabajoAsignado?> trabajoAsignado() {
    final consulta =
        _db.select(_db.trabajoCatalogo).join([
            // `leftOuterJoin` en los tres: sin FK (pull incremental), una
            // orden o lote que todavía no llegó no esconde el trabajo.
            leftOuterJoin(
              _db.ordenCatalogo,
              _db.ordenCatalogo.id.equalsExp(_db.trabajoCatalogo.ordenId),
            ),
            leftOuterJoin(
              _db.loteCatalogo,
              _db.loteCatalogo.id.equalsExp(_db.trabajoCatalogo.loteId),
            ),
            leftOuterJoin(
              _db.trabajoLocal,
              _db.trabajoLocal.uuidCliente.equalsExp(
                _db.trabajoCatalogo.uuidCliente,
              ),
            ),
          ])
          // Sin los retirados (tarea 26): `trabajos_retirados` de
          // `agrocom-api` #313 o el barrido completo.
          ..where(
            _db.trabajoCatalogo.motivoRetiro.isNull() &
                (_db.trabajoLocal.estado.isNull() |
                    _db.trabajoLocal.estado.equalsValue(
                      EstadoTrabajoLocal.abierto,
                    )),
          )
          ..orderBy([
            OrderingTerm.desc(_db.trabajoCatalogo.updatedAt),
            OrderingTerm.desc(_db.trabajoCatalogo.id),
          ])
          ..limit(1);

    return consulta.watch().map(
      (filas) => filas.isEmpty ? null : _desdeFila(filas.single),
    );
  }

  /// Lo que este dispositivo tiene en curso (tarea 27): la sesión abierta
  /// o, si no hay ninguna, el trabajo abierto; `null` si no hay nada.
  /// Sale de `SesionLocal`/`TrabajoLocal` — no de `TrabajoCatalogo` —, así
  /// que aparece aunque el trabajo esté retirado o lo haya abierto la app.
  ///
  /// El modelo admite más de uno abierto a la vez (nada impide abrir un
  /// trabajo desde «Órdenes» con otro abierto), y esta consulta no lo
  /// resuelve: devuelve el más reciente por `ColaSync.secuencia`, el orden
  /// causal global del dispositivo (invariante 5, nunca el reloj). Para un
  /// trabajo, la secuencia mayor entre su apertura y las de sus sesiones;
  /// un trabajo asignado sin sesiones no encoló nada (la apertura es del
  /// panel) y queda detrás, por orden de inserción local (`rowid`).
  Stream<TrabajoEnCurso?> enCurso() {
    // `ORDER BY` afuera de la unión: en SQLite el de un `UNION ALL` solo
    // acepta columnas, no expresiones como `orden IS NULL`.
    final consulta = _db.customSelect(
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

    return consulta.watch().map((filas) {
      if (filas.isEmpty) return null;
      final fila = filas.single;
      return TrabajoEnCurso(
        trabajoUuidCliente: fila.read<String>('trabajo_uuid'),
        sesionUuidCliente: fila.readNullable<String>('sesion_uuid'),
        inicio: fila.read<DateTime>('inicio'),
        loteCodigo: fila.readNullable<String>('lote_codigo'),
        motivoRetiro: fila.readNullable<String>('motivo_retiro'),
      );
    });
  }

  TrabajoAsignado _desdeFila(TypedResult fila) {
    final trabajo = fila.readTable(_db.trabajoCatalogo);
    final orden = fila.readTableOrNull(_db.ordenCatalogo);
    final lote = fila.readTableOrNull(_db.loteCatalogo);
    return TrabajoAsignado(
      id: trabajo.id,
      uuidCliente: trabajo.uuidCliente,
      ordenId: trabajo.ordenId,
      loteId: trabajo.loteId,
      hectareasDeclaradas: trabajo.hectareasDeclaradas,
      equipoTrabajoId: trabajo.equipoTrabajoId,
      updatedAt: trabajo.updatedAt,
      loteCodigo: lote?.codigo,
      nroAplicacion: orden?.nroAplicacion,
      litrosHa: orden?.litrosHa,
      kilosPorVuelo: orden?.kilosPorVuelo,
      cantidadLotesOrden: orden?.cantidadLotes,
      humedadMinPct: trabajo.humedadMinPct,
      vientoMaxKmh: trabajo.vientoMaxKmh,
      temperaturaMaxC: trabajo.temperaturaMaxC,
      humedadMaxPct: trabajo.humedadMaxPct,
      alturaVueloM: trabajo.alturaVueloM,
      velocidadVueloKmh: trabajo.velocidadVueloKmh,
      anchoPasadaM: trabajo.anchoPasadaM,
    );
  }
}
