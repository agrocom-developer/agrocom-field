import 'package:drift/drift.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/trabajo_local.dart' show EstadoTrabajoLocal;
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
  ///
  /// Los límites climáticos y de vuelo (tarea 23) salen del trabajo
  /// asignado de cada orden, no de la orden: el servidor los movió a
  /// `trabajos[]`. El join con `trabajo_catalogo` y `trabajo_local` trae una
  /// fila por cada trabajo de la orden (o una sola, sin trabajo, si no
  /// tiene), y [_trabajoAsignado] elige uno en Dart. Los dos joins quedan en
  /// la consulta para que el `Stream` reaccione también cuando llega un
  /// trabajo o el piloto lo cierra.
  Stream<List<OrdenVigente>> ordenesVigentes() {
    final consulta =
        _db.select(_db.ordenCatalogo).join([
            leftOuterJoin(
              _db.loteCatalogo,
              _db.loteCatalogo.id.equalsExp(_db.ordenCatalogo.loteId),
            ),
            leftOuterJoin(
              _db.trabajoCatalogo,
              _db.trabajoCatalogo.ordenId.equalsExp(_db.ordenCatalogo.id),
            ),
            leftOuterJoin(
              _db.trabajoLocal,
              _db.trabajoLocal.uuidCliente.equalsExp(
                _db.trabajoCatalogo.uuidCliente,
              ),
            ),
          ])
          ..where(_db.ordenCatalogo.estado.equals('vigente'))
          ..orderBy([OrderingTerm.desc(_db.ordenCatalogo.fechaEmision)]);

    return consulta.watch().map(_ordenesDesdeFilas);
  }

  List<OrdenVigente> _ordenesDesdeFilas(List<TypedResult> filas) {
    // Mapa con orden de inserción: conserva el orden de la consulta (por
    // fecha de emisión) aunque cada orden llegue repetida por trabajo.
    final filasPorOrden = <int, List<TypedResult>>{};
    for (final fila in filas) {
      final id = fila.readTable(_db.ordenCatalogo).id;
      filasPorOrden.putIfAbsent(id, () => []).add(fila);
    }
    return filasPorOrden.values
        .map((filasOrden) => _ordenVigente(filasOrden.first, filasOrden))
        .toList();
  }

  /// Misma regla que «el trabajo asignado» de `InicioRepository`: de los
  /// trabajos de la orden que este dispositivo no cerró, el más reciente
  /// por `updated_at` del servidor y, a igual `updated_at`, el de `id`
  /// mayor. Así el detalle de la orden y «Inicio» muestran los límites del
  /// mismo trabajo. `null` si la orden no tiene ninguno: la pantalla dice
  /// «sin datos», nunca toma los límites de otro trabajo cerrado.
  TrabajoCatalogoData? _trabajoAsignado(List<TypedResult> filasOrden) {
    TrabajoCatalogoData? elegido;
    for (final fila in filasOrden) {
      final trabajo = fila.readTableOrNull(_db.trabajoCatalogo);
      if (trabajo == null) continue;
      final local = fila.readTableOrNull(_db.trabajoLocal);
      if (local != null && local.estado != EstadoTrabajoLocal.abierto) {
        continue;
      }
      if (elegido == null ||
          trabajo.updatedAt.isAfter(elegido.updatedAt) ||
          (trabajo.updatedAt.isAtSameMomentAs(elegido.updatedAt) &&
              trabajo.id > elegido.id)) {
        elegido = trabajo;
      }
    }
    return elegido;
  }

  OrdenVigente _ordenVigente(TypedResult fila, List<TypedResult> filasOrden) {
    final orden = fila.readTable(_db.ordenCatalogo);
    final lote = fila.readTableOrNull(_db.loteCatalogo);
    final trabajo = _trabajoAsignado(filasOrden);
    return OrdenVigente(
      id: orden.id,
      contratoId: orden.contratoId,
      loteId: orden.loteId,
      nroAplicacion: orden.nroAplicacion,
      litrosHa: orden.litrosHa,
      kilosPorVuelo: orden.kilosPorVuelo,
      humedadMinPct: trabajo?.humedadMinPct,
      vientoMaxKmh: trabajo?.vientoMaxKmh,
      temperaturaMaxC: trabajo?.temperaturaMaxC,
      humedadMaxPct: trabajo?.humedadMaxPct,
      velocidadMaxKmh: orden.velocidadMaxKmh,
      alturaVueloM: trabajo?.alturaVueloM,
      velocidadVueloKmh: trabajo?.velocidadVueloKmh,
      anchoPasadaM: trabajo?.anchoPasadaM,
      observaciones: orden.observaciones,
      emitidaPorContactoId: orden.emitidaPorContactoId,
      fechaEmision: orden.fechaEmision,
      estado: orden.estado,
      updatedAt: orden.updatedAt,
      cantidadLotes: orden.cantidadLotes,
      hectareasSolicitadas: orden.hectareasSolicitadas,
      loteCodigo: lote?.codigo,
      loteHectareas: lote?.hectareas,
    );
  }
}
