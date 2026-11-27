import 'package:decimal/decimal.dart';

import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';

/// Traducción del JSON de la API (`SolicitudAbierta`, `Oferta`, `Mensaje`,
/// `PreferenciasDeAviso`) al dominio. Hectáreas y dinero llegan como texto
/// decimal y nunca pasan por `double` (ADR 0002).
abstract final class MapeoNegociacion {
  static Decimal decimal(Object? valor, [Decimal? porDefecto]) {
    if (valor == null) return porDefecto ?? Decimal.zero;
    return Decimal.tryParse('$valor') ?? porDefecto ?? Decimal.zero;
  }

  static Decimal? decimalOpcional(Object? valor) =>
      valor == null ? null : Decimal.tryParse('$valor');

  static DateTime? fecha(Object? valor) =>
      valor == null ? null : DateTime.tryParse('$valor');

  /// Contorno de un polígono GeoJSON (`[[[lon, lat], ...]]`), sin el vértice
  /// de cierre repetido.
  static List<GeoPunto> poligono(Object? geometria) {
    if (geometria is! Map) return const [];
    final anillos = geometria['coordinates'];
    if (anillos is! List || anillos.isEmpty || anillos.first is! List) {
      return const [];
    }
    final puntos = <GeoPunto>[
      for (final c in anillos.first as List)
        if (c is List && c.length >= 2)
          GeoPunto((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];
    if (puntos.length > 1 && puntos.first == puntos.last) {
      puntos.removeLast();
    }
    return puntos;
  }

  static GeoPunto? punto(Object? centro) {
    if (centro is! Map) return null;
    final lat = centro['latitud'];
    final lon = centro['longitud'];
    if (lat is! num || lon is! num) return null;
    return GeoPunto(lat.toDouble(), lon.toDouble());
  }

  static SolicitudAbierta solicitud(Map<String, dynamic> j) {
    final terreno = j['terreno'];
    Lote? lote;
    if (terreno is Map) {
      final poligonoTerreno = poligono(terreno['geometria']);
      if (poligonoTerreno.length >= 3) {
        lote = Lote(
          id: 'terreno-${j['id']}',
          nombre: '${terreno['nombre'] ?? 'Terreno'}',
          zona: '${j['zona'] ?? ''}',
          cultivo: '${terreno['cultivo'] ?? j['cultivo'] ?? ''}',
          hectareas: decimal(terreno['hectareas']),
          poligono: poligonoTerreno,
          fotos: FotoTerreno.lista(terreno['fotos']),
        );
      }
    }
    return SolicitudAbierta(
      id: j['id'] as int,
      centro: punto(j['centro']),
      hectareas: decimal(j['hectareas_solicitadas']),
      precioHaPropuesto: decimal(j['precio_ha_propuesto']),
      ofertasVigentes: (j['ofertas_vigentes'] as num?)?.toInt() ?? 0,
      zona: j['zona'] as String?,
      zonaId: (j['zona_id'] as num?)?.toInt(),
      macrorregion: Macrorregion.deCodigo(j['macrorregion'] as String?),
      cultivo: j['cultivo'] as String?,
      tipoAplicacion: j['tipo_aplicacion'] as String?,
      ventanaDesde: fecha(j['ventana_desde']),
      ventanaHasta: fecha(j['ventana_hasta']),
      miNegociacion: MiNegociacion.deCodigo(j['mi_negociacion'] as String?),
      distanciaKm: decimalOpcional(j['distancia_km']),
      venceEn: fecha(j['vence_en']),
      productoIndicado: j['producto_indicado'] as String?,
      aportaProducto: j['aporta_producto'] as String?,
      urgente: j['urgente'] == true,
      observaciones: j['observaciones'] as String?,
      terreno: lote,
      accesoDificil: terreno is Map && terreno['acceso_dificil'] == true,
      referenciasAcceso: terreno is Map
          ? terreno['referencias_acceso'] as String?
          : null,
      colindantesSensibles: terreno is Map
          ? terreno['colindantes_sensibles'] as String?
          : null,
      justificacionPrecio: j['justificacion_precio'] as String?,
    );
  }

  static ResumenZona zona(Map<String, dynamic> j) => ResumenZona(
    zonaId: (j['zona_id'] as num?)?.toInt(),
    zona: '${j['zona'] ?? 'Sin zona'}',
    macrorregion: Macrorregion.deCodigo(j['macrorregion'] as String?),
    solicitudes: (j['solicitudes'] as num?)?.toInt() ?? 0,
    hectareas: decimal(j['hectareas_total']),
    precioHaPromedio: decimal(j['precio_ha_promedio']),
    centro: punto(j['centro']),
  );

  static OfertaNegociada oferta(Map<String, dynamic> j) => OfertaNegociada(
    id: j['id'] as int,
    uuidCliente: '${j['uuid_cliente']}',
    solicitudId: j['solicitud_id'] as int,
    numero: (j['numero'] as num?)?.toInt() ?? 1,
    autor: j['autor'] == 'cliente'
        ? AutorOferta.cliente
        : AutorOferta.proveedor,
    tipo: j['tipo'] == 'acepta_propuesta'
        ? TipoOferta.aceptaPropuesta
        : TipoOferta.contraoferta,
    precioHa: decimal(j['precio_ha']),
    monto: decimal(j['monto_estimado']),
    estado: switch (j['estado']) {
      'vigente' => EstadoOferta.vigente,
      'aceptada' => EstadoOferta.aceptada,
      'reemplazada' => EstadoOferta.reemplazada,
      'rechazada' => EstadoOferta.rechazada,
      'retirada' => EstadoOferta.retirada,
      'vencida' => EstadoOferta.vencida,
      _ => EstadoOferta.cerrada,
    },
    esDefinitiva: j['es_definitiva'] == true,
    venceEn: fecha(j['vence_en']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    nota: j['nota'] as String?,
    justificacionPrecio: j['justificacion_precio'] as String?,
    distanciaKm: decimalOpcional(j['distancia_km']),
    creadaEn: fecha(j['creada_en']),
    respondidaEn: fecha(j['respondida_en']),
    zona: j['zona'] as String?,
    lote: j['lote'] as String?,
  );

  static MensajeChat mensaje(Map<String, dynamic> j) => MensajeChat(
    id: j['id'] as int,
    uuidCliente: '${j['uuid_cliente']}',
    solicitudId: j['solicitud_id'] as int,
    propio: j['propio'] == true,
    texto: '${j['texto']}',
    creadoEn: fecha(j['creado_en']) ?? DateTime.now(),
    leido: j['leido_en'] != null,
  );

  static PreferenciasAviso preferencias(Map<String, dynamic> j) {
    final nuevas = j['nuevas_solicitudes'];
    final mapa = nuevas is Map ? nuevas : const {};
    return PreferenciasAviso(
      nuevasSolicitudes: mapa['activo'] != false,
      macrorregiones: [
        for (final m in (mapa['macrorregiones'] as List? ?? const []))
          ?Macrorregion.deCodigo('$m'),
      ],
      hectareasMinimas: decimalOpcional(mapa['hectareas_minimas']),
      departamentosExcluidos: [
        for (final d in (mapa['departamentos_excluidos'] as List? ?? const []))
          '$d',
      ],
      tiposAplicacionExcluidos: [
        for (final t
            in (mapa['tipos_aplicacion_excluidos'] as List? ?? const []))
          '$t',
      ],
      ofertas: j['ofertas'] != false,
      mensajes: j['mensajes'] != false,
      avance: j['avance'] != false,
      calificaciones: j['calificaciones'] != false,
    );
  }

  static Map<String, dynamic> preferenciasAJson(PreferenciasAviso p) => {
    'nuevas_solicitudes': {
      'activo': p.nuevasSolicitudes,
      // El contrato vigente no conoce `macrorregiones` (un 422 rechazaría
      // todo el guardado); los filtros son por departamento y tipo.
      'hectareas_minimas': p.hectareasMinimas?.toString(),
      'departamentos_excluidos': p.departamentosExcluidos,
      'tipos_aplicacion_excluidos': p.tiposAplicacionExcluidos,
    },
    'ofertas': p.ofertas,
    'mensajes': p.mensajes,
    'avance': p.avance,
    'calificaciones': p.calificaciones,
  };

  /// Parámetros de consulta del mapa a partir de los filtros.
  static Map<String, dynamic> consulta(
    FiltrosMapa f, {
    String? cursor,
    double? lat,
    double? lon,
  }) => {
    if (f.macrorregion != null) 'macrorregion': f.macrorregion!.codigo,
    'zona_id': ?f.zonaId,
    if (f.hectareasMin != null) 'hectareas_min': f.hectareasMin.toString(),
    if (f.hectareasMax != null) 'hectareas_max': f.hectareasMax.toString(),
    if (f.precioHaMin != null) 'precio_ha_min': f.precioHaMin.toString(),
    if (f.precioHaMax != null) 'precio_ha_max': f.precioHaMax.toString(),
    if (f.cultivo != null && f.cultivo!.isNotEmpty) 'cultivo': f.cultivo,
    'orden': f.orden.codigo,
    'cursor': ?cursor,
    'lat': ?lat,
    'lon': ?lon,
  };
}
