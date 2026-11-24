import '../../../dominio/dominio.dart';

/// Bandeja de ofertas del proveedor. Lectura en línea; aceptar y rechazar
/// van directo a la API, sin outbox, con clave de idempotencia generada en
/// el dispositivo (ADR 0009). Es la única acción del proveedor que exige red.
abstract interface class OfertasRepositorio {
  /// Ofertas vigentes; emite de nuevo al llegar, vencer o resolverse una.
  Stream<List<Oferta>> observar();

  Future<ResultadoRespuestaOferta> aceptar(
    String ofertaId, {
    required String claveIdempotencia,
  });

  Future<ResultadoRespuestaOferta> rechazar(
    String ofertaId, {
    required String claveIdempotencia,
  });
}
