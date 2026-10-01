import 'package:decimal/decimal.dart';

/// Orden de aplicación vigente tal como la necesita la pantalla de HU-04:
/// los campos de `OrdenCatalogo` más `loteCodigo`/`loteHectareas`, que
/// pueden faltar porque el pull de catálogo es incremental por cursor y el
/// lote puede no haber llegado todavía (ver comentario en
/// `nucleo/db/tablas/lote_catalogo.dart`).
///
/// Entidad Dart pura, sin dependencia de `drift` ni `dio`: testeable sin
/// emulador (ADR 0005).
class OrdenVigente {
  const OrdenVigente({
    required this.id,
    required this.contratoId,
    required this.loteId,
    required this.nroAplicacion,
    required this.fechaEmision,
    required this.estado,
    required this.updatedAt,
    this.litrosHa,
    this.kilosPorVuelo,
    this.humedadMinPct,
    this.vientoMaxKmh,
    this.temperaturaMaxC,
    this.humedadMaxPct,
    this.velocidadMaxKmh,
    this.alturaVueloM,
    this.velocidadVueloKmh,
    this.anchoPasadaM,
    this.observaciones,
    this.emitidaPorContactoId,
    this.cantidadLotes,
    this.hectareasSolicitadas,
    this.loteCodigo,
    this.loteHectareas,
  });

  final int id;
  final int contratoId;
  final int loteId;
  final int nroAplicacion;

  /// Litros por hectárea si la categoría de insumo es líquida; `null` si es
  /// sólida (HU-79 de `agrocom-api` — mutuamente excluyente con
  /// [kilosPorVuelo], nunca ambos ni ninguno con datos reales).
  final Decimal? litrosHa;
  final Decimal? kilosPorVuelo;

  // Límites climáticos y parámetros de vuelo (tarea 23): los del trabajo
  // asignado de esta orden, no de la orden — el servidor los movió de
  // `ordenes[]` a `trabajos[]`. `null` si la orden no tiene trabajo asignado
  // o si el jefe de campo no los completó; la pantalla dice «sin datos».
  final Decimal? humedadMinPct;
  final Decimal? vientoMaxKmh;
  final Decimal? temperaturaMaxC;
  final Decimal? humedadMaxPct;
  final Decimal? alturaVueloM;
  final Decimal? velocidadVueloKmh;
  final Decimal? anchoPasadaM;

  /// Sigue saliendo de `orden_catalogo`: el servidor ya no lo manda en
  /// ningún lado (no es uno de los siete que pasaron a `trabajos[]`), así
  /// que hoy queda en `null` salvo en filas bajadas de un servidor anterior.
  final Decimal? velocidadMaxKmh;
  final String? observaciones;
  final int? emitidaPorContactoId;
  final String fechaEmision;
  final String estado;
  final DateTime updatedAt;

  /// Cuántos lotes cubre la orden (`lotes.length` del contrato, TE-23). Con
  /// ADR 0022 de `agrocom-api` puede ser más de uno aunque [loteId] sea solo
  /// el primero. `null` en una orden bajada antes de la migración v10 que el
  /// pull todavía no volvió a traer.
  final int? cantidadLotes;

  /// Suma de `lotes[].hectareas_solicitadas`: las hectáreas de la orden
  /// entera, no las de [loteId]. `null` por el mismo motivo que
  /// [cantidadLotes].
  final Decimal? hectareasSolicitadas;

  /// Lotes de la orden que no son [loteId] — `0` si cubre uno solo o si
  /// [cantidadLotes] todavía no llegó.
  int get otrosLotes {
    final cantidad = cantidadLotes;
    return cantidad == null || cantidad <= 1 ? 0 : cantidad - 1;
  }

  /// Hectáreas que la pantalla presenta como «de la orden»: la suma de
  /// `lotes[]` cuando ya llegó; si no (fila de antes de v10, hasta el
  /// próximo pull), la superficie del único lote conocido — lo mismo que se
  /// mostraba antes de TE-23, nunca la de un lote como si fuera la de varios
  /// cuando la suma ya está disponible.
  Decimal? get hectareasOrden => hectareasSolicitadas ?? loteHectareas;

  /// `null` cuando el lote todavía no llegó por el pull incremental — la
  /// pantalla de detalle lo muestra como "sin datos", nunca lo oculta.
  final String? loteCodigo;
  final Decimal? loteHectareas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdenVigente &&
          other.id == id &&
          other.contratoId == contratoId &&
          other.loteId == loteId &&
          other.nroAplicacion == nroAplicacion &&
          other.litrosHa == litrosHa &&
          other.kilosPorVuelo == kilosPorVuelo &&
          other.humedadMinPct == humedadMinPct &&
          other.vientoMaxKmh == vientoMaxKmh &&
          other.temperaturaMaxC == temperaturaMaxC &&
          other.humedadMaxPct == humedadMaxPct &&
          other.velocidadMaxKmh == velocidadMaxKmh &&
          other.alturaVueloM == alturaVueloM &&
          other.velocidadVueloKmh == velocidadVueloKmh &&
          other.anchoPasadaM == anchoPasadaM &&
          other.observaciones == observaciones &&
          other.emitidaPorContactoId == emitidaPorContactoId &&
          other.fechaEmision == fechaEmision &&
          other.estado == estado &&
          other.updatedAt == updatedAt &&
          other.cantidadLotes == cantidadLotes &&
          other.hectareasSolicitadas == hectareasSolicitadas &&
          other.loteCodigo == loteCodigo &&
          other.loteHectareas == loteHectareas);

  @override
  int get hashCode => Object.hashAll([
    id,
    contratoId,
    loteId,
    nroAplicacion,
    litrosHa,
    kilosPorVuelo,
    humedadMinPct,
    vientoMaxKmh,
    temperaturaMaxC,
    humedadMaxPct,
    velocidadMaxKmh,
    alturaVueloM,
    velocidadVueloKmh,
    anchoPasadaM,
    observaciones,
    emitidaPorContactoId,
    fechaEmision,
    estado,
    updatedAt,
    cantidadLotes,
    hectareasSolicitadas,
    loteCodigo,
    loteHectareas,
  ]);
}
