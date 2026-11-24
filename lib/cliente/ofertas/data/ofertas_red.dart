import 'package:decimal/decimal.dart';

import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/oferta_recibida.dart';
import '../domain/ofertas_repositorio.dart';

/// Ofertas de una solicitud contra la API (`/api/solicitudes/{id}/ofertas` y
/// `/api/ofertas/{id}/…`). Cada respuesta cambia la solicitud (adjudica, o
/// cambia su estado), así que después de escribir se vuelve a leer.
class OfertasRed implements OfertasRepositorio {
  OfertasRed(this._http, this._fuente);

  final ClienteHttp _http;
  final FuenteSolicitudes _fuente;

  @override
  Future<List<OfertaRecibida>> deLaSolicitud(String solicitudId) async {
    final r = await _http.obtener('/api/solicitudes/$solicitudId/ofertas');
    final lista = r['ofertas'];
    if (lista is! List) return const [];
    final ofertas = [
      for (final o in lista)
        if (o is Map) MapeoSolicitud.oferta(Map<String, dynamic>.from(o)),
    ];
    // La vigente primero; entre vigentes, la de menor precio por hectárea.
    ofertas.sort((a, b) {
      final va = a.estado == EstadoOferta.vigente ? 0 : 1;
      final vb = b.estado == EstadoOferta.vigente ? 0 : 1;
      if (va != vb) return va - vb;
      return a.precioHa.compareTo(b.precioHa);
    });
    return ofertas;
  }

  @override
  Future<void> aceptar(String ofertaId) async {
    await _http.enviar('/api/ofertas/$ofertaId/aceptar');
    await _fuente.invalidar();
  }

  @override
  Future<void> contraofertar(
    String ofertaId, {
    required Decimal precioHa,
    required String claveIdempotencia,
    String? nota,
  }) async {
    final texto = nota?.trim();
    await _http.enviar(
      '/api/ofertas/$ofertaId/contraofertar',
      datos: {
        'precio_ha': '$precioHa',
        'uuid_cliente': claveIdempotencia,
        if (texto != null && texto.isNotEmpty) 'nota': texto,
      },
    );
    await _fuente.invalidar();
  }

  @override
  Future<void> rechazar(String ofertaId) async {
    await _http.enviar('/api/ofertas/$ofertaId/rechazar');
    await _fuente.invalidar();
  }
}
