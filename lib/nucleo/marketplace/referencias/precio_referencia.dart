import 'package:decimal/decimal.dart';

import '../../api/marketplace_http.dart';

/// De dónde salió el precio de referencia, de lo más específico a lo más
/// general.
enum NivelPrecio {
  zona,
  macrorregion,
  general,
  respaldo;

  static NivelPrecio? desdeApi(Object? v) {
    for (final n in values) {
      if (n.name == v) return n;
    }
    return null;
  }
}

/// Precio por hectárea de referencia: una guía para quien pone su precio, no
/// un límite. [precioHa] es `null` cuando el servidor no tiene referencia.
class PrecioReferencia {
  const PrecioReferencia({
    required this.tipoAplicacion,
    this.zonaId,
    this.macrorregion,
    this.precioHa,
    this.nivel,
  });

  factory PrecioReferencia.desdeJson(Map<String, dynamic> j) {
    final precio = j['precio_ha'];
    return PrecioReferencia(
      tipoAplicacion: '${j['tipo_aplicacion']}',
      zonaId: (j['zona_id'] as num?)?.toInt(),
      macrorregion: j['macrorregion'] as String?,
      precioHa: precio == null ? null : Decimal.parse('$precio'),
      nivel: NivelPrecio.desdeApi(j['nivel']),
    );
  }

  final String tipoAplicacion;
  final int? zonaId;
  final String? macrorregion;

  /// Decimal exacto (ADR 0002).
  final Decimal? precioHa;
  final NivelPrecio? nivel;
}

abstract interface class ReferenciasRepositorio {
  /// Precio por hectárea de referencia para [tipoAplicacion] (`herbicida`,
  /// `insecticida`, `fungicida`, `fertilizante_foliar`, `desecante`,
  /// `otro`), con la [zonaId] o la [macrorregion] si se conocen.
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  });
}

class ReferenciasRed implements ReferenciasRepositorio {
  ReferenciasRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  }) async {
    final r = await _http.obtener(
      '/api/referencias/precio',
      query: {
        'tipo_aplicacion': tipoAplicacion,
        'zona_id': ?zonaId,
        'macrorregion': ?macrorregion,
      },
    );
    return PrecioReferencia.desdeJson(r);
  }
}

/// En memoria: un precio por tipo, igual para todas las zonas.
class ReferenciasDemo implements ReferenciasRepositorio {
  ReferenciasDemo([Map<String, Decimal>? precios])
    : _precios = precios ?? _porDefecto;

  final Map<String, Decimal> _precios;

  static final _porDefecto = {
    'herbicida': Decimal.parse('132'),
    'insecticida': Decimal.parse('145'),
    'fungicida': Decimal.parse('150'),
    'fertilizante_foliar': Decimal.parse('120'),
    'desecante': Decimal.parse('138'),
    'otro': Decimal.parse('130'),
  };

  @override
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  }) async => PrecioReferencia(
    tipoAplicacion: tipoAplicacion,
    zonaId: zonaId,
    macrorregion: macrorregion,
    precioHa: _precios[tipoAplicacion],
    nivel: _precios.containsKey(tipoAplicacion) ? NivelPrecio.general : null,
  );
}
