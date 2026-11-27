import 'package:decimal/decimal.dart';

import '../../../../api/marketplace_http.dart';
import '../../../precio/justificacion_precio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'mapeo_negociacion.dart';

/// Mapa de solicitudes abiertas y primera oferta, contra la API
/// (`/api/solicitudes-abiertas`, `/api/solicitudes/{id}/ofertas`). Sin
/// outbox: ofertar es una acción de dos partes que el servidor resuelve de
/// forma atómica (ADR 0016).
class MercadoRed implements MercadoRepositorio {
  MercadoRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<PaginaSolicitudes> solicitudes(
    FiltrosMapa filtros, {
    String? cursor,
    double? lat,
    double? lon,
  }) async {
    final cuerpo = await _http.obtener(
      '/api/solicitudes-abiertas',
      query: MapeoNegociacion.consulta(
        filtros,
        cursor: cursor,
        lat: lat,
        lon: lon,
      ),
    );
    return PaginaSolicitudes(
      solicitudes: [
        for (final s in (cuerpo['solicitudes'] as List? ?? const []))
          MapeoNegociacion.solicitud(Map<String, dynamic>.from(s as Map)),
      ],
      siguienteCursor: cuerpo['siguiente_cursor'] as String?,
    );
  }

  @override
  Future<List<ResumenZona>> resumenZonas(FiltrosMapa filtros) async {
    final consulta = MapeoNegociacion.consulta(filtros)
      ..remove('orden')
      ..remove('cursor');
    final cuerpo = await _http.obtener(
      '/api/solicitudes-abiertas/resumen-zonas',
      query: consulta,
    );
    return [
      for (final z in (cuerpo['zonas'] as List? ?? const []))
        MapeoNegociacion.zona(Map<String, dynamic>.from(z as Map)),
    ];
  }

  @override
  Future<SolicitudAbierta> detalle(int solicitudId) async {
    final cuerpo = await _http.obtener(
      '/api/solicitudes-abiertas/$solicitudId',
    );
    return MapeoNegociacion.solicitud(
      Map<String, dynamic>.from(cuerpo['solicitud'] as Map),
    );
  }

  @override
  Future<OfertaNegociada> ofertar({
    required int solicitudId,
    required String uuidCliente,
    required TipoOferta tipo,
    Decimal? precioHa,
    String? nota,
    String? justificacionPrecio,
  }) async {
    final cuerpo = await _http.enviar(
      '/api/solicitudes/$solicitudId/ofertas',
      datos: {
        'uuid_cliente': uuidCliente,
        'tipo': tipo == TipoOferta.aceptaPropuesta
            ? 'acepta_propuesta'
            : 'contraoferta',
        if (tipo == TipoOferta.contraoferta && precioHa != null)
          'precio_ha': precioHa.toString(),
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        // El total (`monto_estimado`) nunca se envía: lo calcula el servidor.
        'justificacion_precio': ?JustificacionPrecio.normalizar(
          justificacionPrecio,
        ),
      },
    );
    return MapeoNegociacion.oferta(
      Map<String, dynamic>.from(cuerpo['oferta'] as Map),
    );
  }
}

/// Mis ofertas y su negociación (`/api/ofertas`).
class NegociacionRed implements NegociacionRepositorio {
  NegociacionRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<List<OfertaNegociada>> misOfertas() async {
    final cuerpo = await _http.obtener('/api/ofertas');
    return [
      for (final o in (cuerpo['ofertas'] as List? ?? const []))
        MapeoNegociacion.oferta(Map<String, dynamic>.from(o as Map)),
    ];
  }

  Future<OfertaNegociada> _accion(String ruta, [Object? datos]) async {
    final cuerpo = await _http.enviar(ruta, datos: datos);
    return MapeoNegociacion.oferta(
      Map<String, dynamic>.from(cuerpo['oferta'] as Map),
    );
  }

  @override
  Future<OfertaNegociada> contraofertar(
    int ofertaId, {
    required Decimal precioHa,
    required String uuidCliente,
    String? nota,
    String? justificacionPrecio,
  }) => _accion('/api/ofertas/$ofertaId/contraofertar', {
    'precio_ha': precioHa.toString(),
    'uuid_cliente': uuidCliente,
    if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
    'justificacion_precio': ?JustificacionPrecio.normalizar(
      justificacionPrecio,
    ),
  });

  @override
  Future<OfertaNegociada> aceptar(int ofertaId) =>
      _accion('/api/ofertas/$ofertaId/aceptar');

  @override
  Future<OfertaNegociada> rechazar(int ofertaId) =>
      _accion('/api/ofertas/$ofertaId/rechazar');

  @override
  Future<OfertaNegociada> retirar(int ofertaId) =>
      _accion('/api/ofertas/$ofertaId/retirar');
}

/// Chat con el cliente (`/api/solicitudes/{id}/mensajes`).
class MensajesRed implements MensajesRepositorio {
  MensajesRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<PaginaMensajes> leer(int solicitudId, {int? despues}) async {
    final cuerpo = await _http.obtener(
      '/api/solicitudes/$solicitudId/mensajes',
      query: {'despues': ?despues},
    );
    return PaginaMensajes(
      mensajes: [
        for (final m in (cuerpo['mensajes'] as List? ?? const []))
          MapeoNegociacion.mensaje(Map<String, dynamic>.from(m as Map)),
      ],
      cursor: (cuerpo['cursor'] as num?)?.toInt(),
      soloLectura: cuerpo['solo_lectura'] == true,
    );
  }

  @override
  Future<MensajeChat> enviar(
    int solicitudId, {
    required String uuidCliente,
    required String texto,
  }) async {
    final cuerpo = await _http.enviar(
      '/api/solicitudes/$solicitudId/mensajes',
      datos: {'uuid_cliente': uuidCliente, 'texto': texto.trim()},
    );
    return MapeoNegociacion.mensaje(
      Map<String, dynamic>.from(cuerpo['mensaje'] as Map),
    );
  }

  @override
  Future<void> marcarLeidos(int solicitudId, {required int hasta}) async {
    await _http.enviar(
      '/api/solicitudes/$solicitudId/mensajes/leidos',
      datos: {'hasta': hasta},
    );
  }
}

/// Preferencias de aviso (`/api/notificaciones/preferencias`).
class AvisosRed implements AvisosRepositorio {
  AvisosRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<PreferenciasAviso> leer() async {
    final cuerpo = await _http.obtener('/api/notificaciones/preferencias');
    return MapeoNegociacion.preferencias(
      Map<String, dynamic>.from(cuerpo['preferencias'] as Map),
    );
  }

  @override
  Future<PreferenciasAviso> guardar(PreferenciasAviso preferencias) async {
    final cuerpo = await _http.guardar(
      '/api/notificaciones/preferencias',
      datos: MapeoNegociacion.preferenciasAJson(preferencias),
    );
    return MapeoNegociacion.preferencias(
      Map<String, dynamic>.from(cuerpo['preferencias'] as Map),
    );
  }
}
