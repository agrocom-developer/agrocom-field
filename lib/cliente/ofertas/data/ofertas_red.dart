import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/precio/justificacion_precio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/comparador_ofertas.dart';
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
  Future<List<OfertaRecibida>> deLaSolicitud(
    String solicitudId, {
    FiltrosOfertas filtros = const FiltrosOfertas(),
  }) async {
    final r = await _http.obtener(
      '/api/solicitudes/$solicitudId/ofertas',
      query: filtros.aConsulta(),
    );
    final lista = r['ofertas'];
    if (lista is! List) return const [];
    final ofertas = [
      for (final o in lista)
        if (o is Map) MapeoSolicitud.oferta(Map<String, dynamic>.from(o)),
    ];
    // El orden lo decide el servidor (vigentes primero); la app lo respeta.
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
    String? justificacionPrecio,
  }) async {
    final texto = nota?.trim();
    final justificacion = JustificacionPrecio.normalizar(justificacionPrecio);
    await _http.enviar(
      '/api/ofertas/$ofertaId/contraofertar',
      datos: {
        'precio_ha': '$precioHa',
        'uuid_cliente': claveIdempotencia,
        if (texto != null && texto.isNotEmpty) 'nota': texto,
        // El total (`monto_estimado`) no se envía: lo calcula el servidor.
        'justificacion_precio': ?justificacion,
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
