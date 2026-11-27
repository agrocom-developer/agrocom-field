import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../nucleo/marketplace/dominio/dominio.dart';
import '../ofertas/domain/comparador_ofertas.dart';
import '../ofertas/domain/oferta_recibida.dart';
import '../solicitudes/domain/solicitud.dart';

/// Zona del catálogo (`GET /api/zonas`): nombre y centroide.
class ZonaCatalogo {
  const ZonaCatalogo({
    required this.id,
    required this.nombre,
    required this.centro,
  });

  final int id;
  final String nombre;
  final GeoPunto centro;
}

/// Traducción entre el JSON de la API (`SolicitudServicio`, `Terreno`) y el
/// dominio de la app. Funciones puras: se prueban sin red. Los importes y las
/// hectáreas viajan como `string` decimal y nunca pasan por `double`
/// (ADR 0002).
abstract final class MapeoSolicitud {
  /// Santa Cruz de la Sierra: centro de reserva cuando un terreno no tiene
  /// geometría ni zona.
  static const centroPorDefecto = GeoPunto(-17.7833, -63.1821);

  static Decimal decimal(Object? valor, [Decimal? porDefecto]) {
    if (valor == null) return porDefecto ?? Decimal.zero;
    return Decimal.tryParse('$valor') ?? porDefecto ?? Decimal.zero;
  }

  static Decimal? decimalOpcional(Object? valor) =>
      valor == null ? null : Decimal.tryParse('$valor');

  static DateTime? fecha(Object? valor) {
    if (valor is! String) return null;
    final f = DateTime.tryParse(valor);
    return f == null ? null : (f.isUtc ? f.toLocal() : f);
  }

  /// Fecha de calendario (`2026-12-06`) como día local, sin hora.
  static DateTime? dia(Object? valor) {
    if (valor is! String) return null;
    final f = DateTime.tryParse(valor);
    return f == null ? null : DateTime(f.year, f.month, f.day);
  }

  /// `2026-12-06`, para enviar una fecha de calendario.
  static String diaApi(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';

  /// Cuántos metros mide un grado de latitud, para dibujar el contorno de
  /// reserva.
  static const _metrosPorGrado = 111320.0;

  /// Contorno del terreno a partir de su GeoJSON (`Polygon` o
  /// `MultiPolygon`). Sin geometría devuelve un cuadrado de reserva centrado
  /// en [centro] con la superficie del terreno, solo para ubicarlo en el
  /// mapa.
  static List<GeoPunto> poligono(
    Object? geometria, {
    required Decimal hectareas,
    required GeoPunto centro,
  }) {
    final real = _poligonoGeoJson(geometria);
    if (real.length >= 3) return real;
    return _cuadradoDeReserva(centro, hectareas);
  }

  static List<GeoPunto> _poligonoGeoJson(Object? geometria) {
    if (geometria is! Map) return const [];
    var coordenadas = geometria['coordinates'];
    if (geometria['type'] == 'MultiPolygon' &&
        coordenadas is List &&
        coordenadas.isNotEmpty) {
      coordenadas = coordenadas.first;
    }
    if (coordenadas is! List || coordenadas.isEmpty) return const [];
    final anillo = coordenadas.first;
    if (anillo is! List) return const [];
    final puntos = <GeoPunto>[];
    for (final par in anillo) {
      if (par is List && par.length >= 2 && par[0] is num && par[1] is num) {
        // GeoJSON ordena [longitud, latitud].
        puntos.add(
          GeoPunto((par[1] as num).toDouble(), (par[0] as num).toDouble()),
        );
      }
    }
    if (puntos.length > 1 && puntos.first == puntos.last) puntos.removeLast();
    return puntos;
  }

  static List<GeoPunto> _cuadradoDeReserva(GeoPunto centro, Decimal hectareas) {
    // Solo geometría de dibujo: la superficie de negocio sigue siendo Decimal.
    final lado = math.sqrt(math.max(hectareas.toDouble(), 0.5) * 10000);
    final dLat = lado / 2 / _metrosPorGrado;
    final dLng =
        lado / 2 / (_metrosPorGrado * math.cos(centro.latitud * math.pi / 180));
    return [
      GeoPunto(centro.latitud - dLat, centro.longitud - dLng),
      GeoPunto(centro.latitud - dLat, centro.longitud + dLng),
      GeoPunto(centro.latitud + dLat, centro.longitud + dLng),
      GeoPunto(centro.latitud + dLat, centro.longitud - dLng),
    ];
  }

  /// `{type: Polygon}` en GeoJSON para un contorno dibujado en la app.
  static Map<String, dynamic> geoJson(List<GeoPunto> poligono) {
    final anillo = [
      for (final p in poligono) [p.longitud, p.latitud],
      [poligono.first.longitud, poligono.first.latitud],
    ];
    return {
      'type': 'Polygon',
      'coordinates': [anillo],
    };
  }

  static Lote lote(
    Map<String, dynamic> terreno, {
    Map<int, ZonaCatalogo> zonas = const {},
    String? cultivoDeSolicitud,
  }) {
    final zonaId = terreno['zona_id'];
    final zona = zonaId is int ? zonas[zonaId] : null;
    final hectareas = decimal(terreno['hectareas']);
    final poligono = MapeoSolicitud.poligono(
      terreno['geometria'],
      hectareas: hectareas,
      centro: zona?.centro ?? centroPorDefecto,
    );
    return Lote(
      id: '${terreno['id']}',
      nombre: '${terreno['nombre'] ?? 'Terreno'}',
      zona: zona?.nombre ?? 'Sin zona asignada',
      cultivo: '${terreno['cultivo'] ?? cultivoDeSolicitud ?? ''}',
      hectareas: hectareas,
      poligono: poligono,
      fotos: FotoTerreno.lista(terreno['fotos']),
    );
  }

  /// Tipo de aplicación del contrato a partir del producto escrito.
  static String tipoAplicacion(String producto) {
    final p = producto.toLowerCase();
    if (p.contains('herbicida') || p.contains('glifosato')) return 'herbicida';
    if (p.contains('insecticida') || p.contains('piretroide')) {
      return 'insecticida';
    }
    if (p.contains('fungicida') ||
        p.contains('triazol') ||
        p.contains('estrobilurina')) {
      return 'fungicida';
    }
    if (p.contains('fertilizante')) return 'fertilizante_foliar';
    if (p.contains('desecante')) return 'desecante';
    return 'otro';
  }

  /// La solicitud tal como la devuelve `GET /api/solicitudes[/{id}]`.
  static Solicitud solicitud(
    Map<String, dynamic> j, {
    Map<int, ZonaCatalogo> zonas = const {},
    int? puntajeDelCliente,
    String? nombreProveedor,
    int? ofertasVigentes,
  }) {
    final terreno = j['terreno'] is Map
        ? Map<String, dynamic>.from(j['terreno'] as Map)
        : <String, dynamic>{
            'id': j['terreno_id'],
            'nombre': 'Terreno',
            'hectareas': j['hectareas_solicitadas'],
          };
    final lote = MapeoSolicitud.lote(
      terreno,
      zonas: zonas,
      cultivoDeSolicitud: j['cultivo'] as String?,
    );
    final historial = <CambioEstado>[];
    final crudo = j['historial'];
    if (crudo is List) {
      for (final paso in crudo) {
        if (paso is! Map) continue;
        final momento = fecha(paso['creado_en']);
        if (momento == null) continue;
        historial.add(
          CambioEstado(
            estado: EstadoSolicitud.desdeApi(paso['estado_nuevo'] as String?),
            momento: momento,
          ),
        );
      }
    }
    final acceso = terreno['referencias_acceso'];
    return Solicitud(
      id: '${j['id']}',
      lote: lote,
      hectareas: decimal(j['hectareas_solicitadas']),
      cultivo: '${j['cultivo'] ?? lote.cultivo}',
      producto: '${j['producto_indicado'] ?? ''}',
      tipoAplicacion: '${j['tipo_aplicacion'] ?? 'otro'}',
      ventanaDesde: dia(j['ventana_desde']) ?? DateTime.now(),
      ventanaHasta:
          dia(j['ventana_hasta']) ?? dia(j['ventana_desde']) ?? DateTime.now(),
      observaciones: j['observaciones'] as String?,
      accesos: acceso is String && acceso.trim().isNotEmpty ? acceso : null,
      precioHaPropuesto: decimal(j['precio_ha_propuesto']),
      precioHaAcordado: decimalOpcional(j['precio_ha_acordado']),
      montoEstimado: decimalOpcional(j['monto_estimado']),
      hectareasEjecutadas: decimalOpcional(j['hectareas_ejecutadas']),
      porcentajeAvance: decimalOpcional(j['porcentaje_avance']),
      montoFinal: decimalOpcional(j['monto_final']),
      estado: EstadoSolicitud.desdeApi(j['estado'] as String?),
      proveedorId: j['proveedor_id'] == null ? null : '${j['proveedor_id']}',
      ofertaAdjudicadaId: j['oferta_adjudicada_id'] == null
          ? null
          : '${j['oferta_adjudicada_id']}',
      venceEn: fecha(j['vence_en']),
      publicadaEn: fecha(j['publicada_en']),
      motivoCancelacion: j['motivo_cancelacion'] as String?,
      historial: historial,
      puntajeDelCliente: puntajeDelCliente,
      nombreProveedor: nombreProveedor,
      ofertasVigentes: ofertasVigentes,
    );
  }

  /// La oferta tal como la devuelve `GET /api/solicitudes/{id}/ofertas`.
  static OfertaRecibida oferta(Map<String, dynamic> j) {
    final p = j['proveedor'] is Map
        ? Map<String, dynamic>.from(j['proveedor'] as Map)
        : <String, dynamic>{};
    final d = p['dron'] is Map
        ? Map<String, dynamic>.from(p['dron'] as Map)
        : <String, dynamic>{};
    final fotos = <FotoDron>[];
    if (d['fotos'] is List) {
      for (final f in d['fotos'] as List) {
        if (f is! Map) continue;
        final url = f['url'] ?? f['archivo'];
        if (url is! String) continue;
        fotos.add(
          FotoDron(id: '${f['id']}', ruta: url, tipo: f['tipo'] as String?),
        );
      }
    }
    final historial = <OfertaRecibida>[];
    if (j['historial'] is List) {
      for (final h in j['historial'] as List) {
        if (h is Map) {
          historial.add(
            oferta({
              ...Map<String, dynamic>.from(h),
              'proveedor': p,
              'historial': null,
            }),
          );
        }
      }
    }
    return OfertaRecibida(
      id: '${j['id']}',
      solicitudId: '${j['solicitud_id']}',
      numero: (j['numero'] as num?)?.toInt() ?? 1,
      autor: j['autor'] == 'cliente'
          ? AutorOferta.cliente
          : AutorOferta.proveedor,
      precioHa: decimal(j['precio_ha']),
      montoEstimado: decimal(j['monto_estimado']),
      estado: EstadoOferta.desdeApi(j['estado'] as String?),
      esDefinitiva: j['es_definitiva'] == true,
      aceptaPropuesta: j['tipo'] == 'acepta_propuesta',
      nota: j['nota'] as String?,
      justificacionPrecio: j['justificacion_precio'] as String?,
      distanciaKm: decimalOpcional(j['distancia_km']),
      venceEn: fecha(j['vence_en']),
      creadaEn: fecha(j['creada_en']),
      ronda: historial,
      proveedor: ProveedorOfertante(
        id: '${j['proveedor_id'] ?? p['id']}',
        nombre: '${p['nombre'] ?? 'Piloto'}',
        calificacion: double.tryParse('${p['calificacion_promedio']}') ?? 0,
        calificaciones: (p['calificaciones_conteo'] as num?)?.toInt() ?? 0,
        tasaCancelacion: double.tryParse('${p['tasa_cancelacion']}') ?? 0,
        marcaDron: d['marca'] as String?,
        modeloDron: d['modelo'] as String?,
        anioDron: (d['anio'] as num?)?.toInt(),
        capacidadLitros: decimalOpcional(d['capacidad_tanque_l']),
        fotosDron: fotos,
        fotoUrl: p['foto_url'] as String?,
        tipo: CodigoTipoProveedor.deCodigo(p['tipo'] as String?),
      ),
    );
  }
}
