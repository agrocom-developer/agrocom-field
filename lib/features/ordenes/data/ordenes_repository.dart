import 'package:drift/drift.dart';

import '../../../nucleo/db/database.dart';
import '../domain/orden_vigente.dart';

/// Repositorio de lectura de HU-04 — nunca escribe `OrdenCatalogo` ni
/// `LoteCatalogo` (eso es TE-06, ya integrada): arma el `Stream` reactivo
/// que consume la pantalla de lista (invariante 1 de CLAUDE.md, la UI nunca
/// lee de la red directo, siempre de `drift`).
///
/// El filtro `estado == 'vigente'` es defensivo: el pull de catálogo del
/// servidor ya solo entrega órdenes vigentes, pero una vez que una orden
/// deja de serlo el servidor no la vuelve a enviar (deja de matchear su
/// filtro), así que la fila local podría quedar con un estado viejo si
/// algún día llega encolada de otra forma. Este filtro no corrige esa
/// limitación — no es alcance de esta tarea — solo evita mostrarla acá.
class OrdenesRepository {
  OrdenesRepository(this._db);

  final AppDatabase _db;

  /// `leftOuterJoin` a propósito: `OrdenCatalogo.loteId` no tiene FK (ver
  /// `orden_catalogo.dart`), así que una orden vigente sin su lote todavía
  /// sincronizado tiene que aparecer igual, con los campos de lote en
  /// `null` — un `innerJoin` la escondería sin avisar.
  Stream<List<OrdenVigente>> ordenesVigentes() {
    final consulta =
        _db.select(_db.ordenCatalogo).join([
            leftOuterJoin(
              _db.loteCatalogo,
              _db.loteCatalogo.id.equalsExp(_db.ordenCatalogo.loteId),
            ),
          ])
          ..where(_db.ordenCatalogo.estado.equals('vigente'))
          ..orderBy([OrderingTerm.desc(_db.ordenCatalogo.fechaEmision)]);

    return consulta.watch().map(
      (filas) => filas.map(_ordenVigenteDesdeFila).toList(),
    );
  }

  OrdenVigente _ordenVigenteDesdeFila(TypedResult fila) {
    final orden = fila.readTable(_db.ordenCatalogo);
    final lote = fila.readTableOrNull(_db.loteCatalogo);
    return OrdenVigente(
      id: orden.id,
      contratoId: orden.contratoId,
      loteId: orden.loteId,
      nroAplicacion: orden.nroAplicacion,
      litrosHa: orden.litrosHa,
      humedadMinPct: orden.humedadMinPct,
      vientoMaxKmh: orden.vientoMaxKmh,
      temperaturaMaxC: orden.temperaturaMaxC,
      humedadMaxPct: orden.humedadMaxPct,
      velocidadMaxKmh: orden.velocidadMaxKmh,
      alturaVueloM: orden.alturaVueloM,
      velocidadVueloKmh: orden.velocidadVueloKmh,
      anchoPasadaM: orden.anchoPasadaM,
      observaciones: orden.observaciones,
      emitidaPorContactoId: orden.emitidaPorContactoId,
      fechaEmision: orden.fechaEmision,
      estado: orden.estado,
      updatedAt: orden.updatedAt,
      loteCodigo: lote?.codigo,
      loteHectareas: lote?.hectareas,
    );
  }
}
