import 'package:decimal/decimal.dart';

/// El precio final de un servicio, como lo cerró el piloto y lo confirma el
/// cliente (`GET /api/solicitudes/{id}/precio-final`). Hectáreas y Bs son
/// decimales exactos (ADR 0002): la app nunca recalcula el monto, lo congela
/// el servidor.
class PrecioFinal {
  const PrecioFinal({
    required this.hectareasEjecutadas,
    required this.precioHaAcordado,
    required this.montoFinal,
    required this.confirmado,
    this.confirmadoEn,
  });

  final Decimal hectareasEjecutadas;
  final Decimal precioHaAcordado;
  final Decimal montoFinal;

  /// El cliente ya lo confirmó. La última decisión es suya.
  final bool confirmado;
  final DateTime? confirmadoEn;

  @override
  bool operator ==(Object other) =>
      other is PrecioFinal &&
      other.hectareasEjecutadas == hectareasEjecutadas &&
      other.precioHaAcordado == precioHaAcordado &&
      other.montoFinal == montoFinal &&
      other.confirmado == confirmado &&
      other.confirmadoEn == confirmadoEn;

  @override
  int get hashCode => Object.hash(
    hectareasEjecutadas,
    precioHaAcordado,
    montoFinal,
    confirmado,
    confirmadoEn,
  );
}
