import 'package:decimal/decimal.dart';

import '../../../nucleo/catalogo/motivo_retiro.dart';

/// Dosis de la orden del trabajo asignado: `litrosHa` o `kilosPorVuelo`,
/// mutuamente excluyentes según la categoría de insumo (HU-79 de
/// `agrocom-api`). La pantalla muestra una sola, nunca las dos.
class DosisTrabajo {
  const DosisTrabajo(this.valor, this.unidad, this.etiqueta);

  final Decimal valor;
  final String unidad;
  final String etiqueta;
}

/// El trabajo que el jefe de campo asignó desde el panel (HU-70), tal como
/// lo necesita la pantalla «Inicio» del piloto: la fila de
/// `TrabajoCatalogo` más lo que se resuelve por join local con la orden y
/// el lote. Todo lo que viene del join puede faltar — el pull es
/// incremental y la orden o el lote pueden no haber llegado todavía — y en
/// ese caso la pantalla dice «sin datos», nunca inventa.
///
/// Entidad Dart pura, testeable sin emulador (ADR 0005).
class TrabajoAsignado {
  const TrabajoAsignado({
    required this.id,
    required this.uuidCliente,
    required this.ordenId,
    required this.loteId,
    required this.hectareasDeclaradas,
    required this.equipoTrabajoId,
    required this.updatedAt,
    this.loteCodigo,
    this.nroAplicacion,
    this.litrosHa,
    this.kilosPorVuelo,
    this.cantidadLotesOrden,
    this.ordenMotivoRetiro,
    this.humedadMinPct,
    this.vientoMaxKmh,
    this.temperaturaMaxC,
    this.humedadMaxPct,
    this.alturaVueloM,
    this.velocidadVueloKmh,
    this.anchoPasadaM,
  });

  final int id;

  /// El `uuid_cliente` que generó el panel, tal cual: es el que se usa para
  /// abrir sesiones sobre este trabajo.
  final String uuidCliente;
  final int ordenId;
  final int loteId;

  /// Hectáreas asignadas a ESTE equipo — no las del lote ni las de la orden.
  final Decimal hectareasDeclaradas;
  final int equipoTrabajoId;
  final DateTime updatedAt;

  /// `LoteCatalogo.codigo`; `null` si el lote no llegó todavía.
  final String? loteCodigo;

  /// `OrdenCatalogo.nroAplicacion`; `null` si la orden no llegó todavía.
  final int? nroAplicacion;
  final Decimal? litrosHa;
  final Decimal? kilosPorVuelo;

  /// `OrdenCatalogo.cantidadLotes`: cuántos lotes cubre la orden entera.
  final int? cantidadLotesOrden;

  /// `OrdenCatalogo.motivoRetiro` (tarea 27): `null` si la orden sigue
  /// vigente o no llegó todavía. Hoy solo importa `pausada`: el servidor no
  /// retira los trabajos de una orden pausada, así que el trabajo sigue
  /// apareciendo como asignado.
  final String? ordenMotivoRetiro;

  /// La orden de este trabajo está pausada: el dueño decidió que no se
  /// vuela sobre ella, aunque el servidor acepte la sesión.
  bool get ordenPausada => ordenMotivoRetiro == MotivoRetiro.ordenPausada;

  // Límites climáticos y parámetros de vuelo de ESTE trabajo (tarea 23):
  // vienen en la propia fila de `TrabajoCatalogo`, no por join. `null`
  // cuando el jefe de campo no los completó al asignar, o en una fila
  // bajada antes de v12 hasta el próximo pull.
  final Decimal? humedadMinPct;
  final Decimal? vientoMaxKmh;
  final Decimal? temperaturaMaxC;
  final Decimal? humedadMaxPct;
  final Decimal? alturaVueloM;
  final Decimal? velocidadVueloKmh;
  final Decimal? anchoPasadaM;

  /// `litrosHa` si viene; si no, `kilosPorVuelo`; si ninguno, `null` —
  /// nunca las dos a la vez.
  DosisTrabajo? get dosis {
    final litros = litrosHa;
    if (litros != null) return DosisTrabajo(litros, 'L/ha', 'L / ha');
    final kilos = kilosPorVuelo;
    if (kilos != null) return DosisTrabajo(kilos, 'kg/vuelo', 'kg / vuelo');
    return null;
  }

  /// «Crear aplicación» necesita la orden ya en el catálogo local:
  /// `TrabajoLocal` copia su `nroAplicacion`, y sin ella habría que
  /// inventarlo.
  bool get puedeCrearAplicacion => nroAplicacion != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrabajoAsignado &&
          other.id == id &&
          other.uuidCliente == uuidCliente &&
          other.ordenId == ordenId &&
          other.loteId == loteId &&
          other.hectareasDeclaradas == hectareasDeclaradas &&
          other.equipoTrabajoId == equipoTrabajoId &&
          other.updatedAt == updatedAt &&
          other.loteCodigo == loteCodigo &&
          other.nroAplicacion == nroAplicacion &&
          other.litrosHa == litrosHa &&
          other.kilosPorVuelo == kilosPorVuelo &&
          other.cantidadLotesOrden == cantidadLotesOrden &&
          other.ordenMotivoRetiro == ordenMotivoRetiro &&
          other.humedadMinPct == humedadMinPct &&
          other.vientoMaxKmh == vientoMaxKmh &&
          other.temperaturaMaxC == temperaturaMaxC &&
          other.humedadMaxPct == humedadMaxPct &&
          other.alturaVueloM == alturaVueloM &&
          other.velocidadVueloKmh == velocidadVueloKmh &&
          other.anchoPasadaM == anchoPasadaM);

  @override
  int get hashCode => Object.hash(
    id,
    uuidCliente,
    ordenId,
    loteId,
    hectareasDeclaradas,
    equipoTrabajoId,
    updatedAt,
    loteCodigo,
    nroAplicacion,
    litrosHa,
    kilosPorVuelo,
    cantidadLotesOrden,
    ordenMotivoRetiro,
    humedadMinPct,
    vientoMaxKmh,
    temperaturaMaxC,
    humedadMaxPct,
    alturaVueloM,
    velocidadVueloKmh,
    anchoPasadaM,
  );
}
