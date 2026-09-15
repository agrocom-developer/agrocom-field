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
  final Decimal? humedadMinPct;
  final Decimal? vientoMaxKmh;
  final Decimal? temperaturaMaxC;
  final Decimal? humedadMaxPct;
  final Decimal? velocidadMaxKmh;
  final Decimal? alturaVueloM;
  final Decimal? velocidadVueloKmh;
  final Decimal? anchoPasadaM;
  final String? observaciones;
  final int? emitidaPorContactoId;
  final String fechaEmision;
  final String estado;
  final DateTime updatedAt;

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
    loteCodigo,
    loteHectareas,
  ]);
}
