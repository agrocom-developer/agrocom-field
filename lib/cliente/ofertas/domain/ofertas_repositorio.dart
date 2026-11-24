import 'package:decimal/decimal.dart';

import 'oferta_recibida.dart';

/// Ofertas que los pilotos hacen a una solicitud del cliente y sus
/// respuestas. Requiere red: el flavor cliente no tiene outbox y negociar es
/// una decisión entre dos partes que el servidor resuelve de forma atómica
/// (ADR 0016).
///
/// Los fallos de red llegan como `SinConexion`; si la oferta cambió
/// (venció, la retiraron, la solicitud ya se adjudicó), como [OfertaCambio].
abstract interface class OfertasRepositorio {
  /// Ofertas de la solicitud, la vigente primero y luego las cerradas.
  Future<List<OfertaRecibida>> deLaSolicitud(String solicitudId);

  /// Acepta la oferta vigente del piloto: adjudica la solicitud.
  Future<void> aceptar(String ofertaId);

  /// Responde con otro precio por hectárea. [claveIdempotencia] nace al abrir
  /// el formulario y se reutiliza en cada reintento.
  Future<void> contraofertar(
    String ofertaId, {
    required Decimal precioHa,
    required String claveIdempotencia,
    String? nota,
  });

  /// Rechaza la oferta: cierra esa negociación.
  Future<void> rechazar(String ofertaId);
}
