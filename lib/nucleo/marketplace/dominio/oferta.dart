import 'package:decimal/decimal.dart';

import 'lote.dart';

/// Oferta de un servicio a un proveedor, con ventana de tiempo. El primero
/// que acepta a tiempo la obtiene; el servidor decide.
class Oferta {
  const Oferta({
    required this.id,
    required this.lote,
    required this.producto,
    required this.pago,
    required this.distanciaKm,
    required this.ventana,
    required this.recibidaEn,
    required this.fechaServicio,
    this.esDeAgrocom = false,
  });

  final String id;
  final Lote lote;
  final String producto;

  /// Lo que gana el proveedor, en bolivianos, decimal exacto.
  final Decimal pago;
  final Decimal distanciaKm;

  /// Tiempo total que el proveedor tiene para responder.
  final Duration ventana;
  final DateTime recibidaEn;
  final DateTime fechaServicio;

  /// Ofrecida primero a la flota propia de Agrocom.
  final bool esDeAgrocom;

  DateTime get venceEn => recibidaEn.add(ventana);

  Duration restante(DateTime ahora) {
    final r = venceEn.difference(ahora);
    return r.isNegative ? Duration.zero : r;
  }
}

enum ResultadoRespuestaOferta {
  /// El proveedor se quedó con el servicio.
  aceptada,

  /// Otro proveedor aceptó antes.
  perdida,

  /// La ventana de tiempo venció.
  expirada,

  /// Rechazo registrado.
  rechazada,

  /// No hay red: aceptar y rechazar la exigen.
  sinConexion,
}
