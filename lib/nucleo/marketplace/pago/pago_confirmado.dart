import 'package:decimal/decimal.dart';

/// Cómo se pagó el servicio, fuera de la aplicación.
enum MetodoPago {
  efectivo('Efectivo', 'efectivo'),
  transferencia('Transferencia', 'transferencia'),
  qr('QR', 'qr'),
  otro('Otro', 'otro');

  const MetodoPago(this.etiqueta, this.api);
  final String etiqueta;

  /// Valor que viaja en el contrato.
  final String api;

  static MetodoPago? desdeApi(Object? valor) {
    for (final m in values) {
      if (m.api == valor) return m;
    }
    return null;
  }
}

/// Registro informativo de que el proveedor recibió el pago. La app no cobra:
/// el pago ocurre fuera y el proveedor titular lo informa una sola vez. El
/// monto lo fija el servidor (el monto final congelado), nunca la app.
class PagoConfirmado {
  const PagoConfirmado({
    required this.id,
    required this.uuidCliente,
    required this.solicitudId,
    required this.monto,
    required this.confirmadoEn,
    this.metodo,
    this.nota,
  });

  factory PagoConfirmado.desdeJson(Map<String, dynamic> j) => PagoConfirmado(
    id: (j['id'] as num).toInt(),
    uuidCliente: '${j['uuid_cliente']}',
    solicitudId: (j['solicitud_id'] as num).toInt(),
    monto: Decimal.parse('${j['monto']}'),
    metodo: MetodoPago.desdeApi(j['metodo']),
    nota: j['nota'] as String?,
    confirmadoEn: DateTime.parse('${j['confirmado_en']}'),
  );

  final int id;
  final String uuidCliente;
  final int solicitudId;

  /// Monto final del servicio al confirmar, decimal exacto (ADR 0002).
  final Decimal monto;
  final MetodoPago? metodo;
  final String? nota;
  final DateTime confirmadoEn;
}
