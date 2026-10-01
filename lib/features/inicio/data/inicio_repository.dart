import 'package:drift/drift.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/trabajo_local.dart' show EstadoTrabajoLocal;
import '../domain/trabajo_asignado.dart';

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
          ..where(
            _db.trabajoLocal.estado.isNull() |
                _db.trabajoLocal.estado.equalsValue(EstadoTrabajoLocal.abierto),
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
