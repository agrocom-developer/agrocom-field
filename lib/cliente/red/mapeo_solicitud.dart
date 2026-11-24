import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../nucleo/marketplace/dominio/dominio.dart';

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

/// Traducción entre el JSON de la API (`SolicitudServicio`, `Terreno`,
/// `EstimacionSolicitud`) y el dominio de la app. Funciones puras: se
/// prueban sin red. Los importes y las hectáreas viajan como `string`
/// decimal y nunca pasan por `double` (ADR 0002).
abstract final class MapeoSolicitud {
  /// Santa Cruz de la Sierra: centro de reserva cuando un terreno no tiene
  /// geometría ni zona.
  static const centroPorDefecto = GeoPunto(-17.7833, -63.1821);

  static Decimal decimal(Object? valor, [Decimal? porDefecto]) {
    if (valor == null) return porDefecto ?? Decimal.zero;
    return Decimal.tryParse('$valor') ?? porDefecto ?? Decimal.zero;
  }

  static DateTime? fecha(Object? valor) {
    if (valor is! String) return null;
    final f = DateTime.tryParse(valor);
    return f == null ? null : (f.isUtc ? f.toLocal() : f);
  }

  static EstadoServicio estado(String? estadoApi) => switch (estadoApi) {
    'borrador' ||
    'publicada' ||
    'en_asignacion' ||
    'sin_proveedor' => EstadoServicio.buscandoProveedor,
    'asignada' || 'en_camino' => EstadoServicio.asignado,
    'en_ejecucion' || 'suspendida_por_clima' => EstadoServicio.enEjecucion,
    'ejecutada' || 'en_disputa' || 'completada' => EstadoServicio.completado,
    'cancelada' => EstadoServicio.cancelado,
    _ => EstadoServicio.buscandoProveedor,
  };

  /// Cuántos metros mide un grado de latitud, para dibujar el contorno de
  /// reserva.
  static const _metrosPorGrado = 111320.0;

  /// Contorno del terreno a partir de su GeoJSON (`Polygon` o
  /// `MultiPolygon`). Sin geometría devuelve un cuadrado de reserva centrado
  /// en [centro] con la superficie del terreno, solo para ubicarlo en el
  /// mapa; el servidor no tiene el contorno real (ver
  /// `docs/gestion/brechas-api.md`).
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
    );
  }

  static final _dosis = RegExp(r',?\s*(\d+(?:[.,]\d+)?)\s*L\s*/\s*ha\s*$');

  /// Separa «Glifosato 480 SL, 2 L/ha» en producto y dosis.
  static (String, Decimal) productoYDosis(String texto) {
    final m = _dosis.firstMatch(texto);
    if (m == null) return (texto.trim(), Decimal.zero);
    final dosis = Decimal.tryParse(m.group(1)!.replaceAll(',', '.'));
    return (texto.substring(0, m.start).trim(), dosis ?? Decimal.zero);
  }

  /// Arma el texto de `producto_indicado` con la dosis (ver [productoYDosis]).
  static String productoIndicado(String producto, Decimal dosis) =>
      '$producto, $dosis L/ha';

  /// Cuándo ocurrió la transición a [estadoNuevo] según el historial.
  static DateTime? momentoDe(
    Map<String, dynamic> solicitud,
    String estadoNuevo,
  ) {
    final historial = solicitud['historial'];
    if (historial is! List) return null;
    for (final paso in historial.reversed) {
      if (paso is Map && paso['estado_nuevo'] == estadoNuevo) {
        return fecha(paso['creado_en']);
      }
    }
    return null;
  }

  /// El proveedor que el cliente ve. La API de solicitudes solo trae
  /// `proveedor_id`; el nombre sale de [nombre] cuando se conoce (las
  /// calificaciones de un servicio completado lo traen).
  static Proveedor? proveedor(
    Map<String, dynamic> solicitud, {
    String? nombre,
  }) {
    final id = solicitud['proveedor_id'];
    if (id == null) return null;
    return Proveedor(
      id: '$id',
      nombre: nombre ?? 'Proveedor asignado',
      tipo: TipoProveedor.independiente,
      calificacion: 0,
      serviciosCompletados: 0,
      zonas: const [],
    );
  }

  static Servicio servicio(
    Map<String, dynamic> j, {
    Map<int, ZonaCatalogo> zonas = const {},
    int? puntajeDelCliente,
    String? nombreProveedor,
    String clienteNombre = 'Cliente',
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
    final (producto, dosis) = productoYDosis('${j['producto_indicado'] ?? ''}');
    final estadoApi = j['estado'] as String?;
    final estadoDominio = estado(estadoApi);
    final declaradas = decimal(j['hectareas_solicitadas']);
    // La API no informa el avance del vuelo al cliente: se da por cubierto
    // el lote completo una vez ejecutado el servicio.
    final terminado =
        estadoApi == 'ejecutada' ||
        estadoApi == 'en_disputa' ||
        estadoApi == 'completada';
    final precio = j['monto_final'] ?? j['monto_estimado'];
    return Servicio(
      id: '${j['id']}',
      lote: Lote(
        id: lote.id,
        nombre: lote.nombre,
        zona: lote.zona,
        cultivo: (j['cultivo'] as String?) ?? lote.cultivo,
        hectareas: lote.hectareas,
        poligono: lote.poligono,
      ),
      producto: producto,
      dosisLitrosPorHectarea: dosis,
      hectareasDeclaradas: declaradas,
      hectareasCubiertas: terminado ? declaradas : Decimal.zero,
      fechaDeseada: fecha(j['ventana_desde']) ?? DateTime.now(),
      estado: estadoDominio,
      precio: decimal(precio),
      solicitadoEn:
          momentoDe(j, 'borrador') ??
          fecha(j['publicada_en']) ??
          fecha(j['ventana_desde']) ??
          DateTime.now(),
      proveedor: proveedor(j, nombre: nombreProveedor),
      puntajeDelCliente: puntajeDelCliente,
      clienteNombre: clienteNombre,
    );
  }

  static EstimacionServicio estimacion(
    Map<String, dynamic> j, {
    required Decimal dosis,
    required Decimal hectareas,
  }) {
    final recargos = <RecargoServicio>[];
    void sumar(String clave, String concepto) {
      final monto = decimal(j[clave]);
      if (monto > Decimal.zero) {
        recargos.add(RecargoServicio(concepto: concepto, monto: monto));
      }
    }

    sumar('recargo_urgente', 'Recargo por urgencia');
    sumar('recargo_acceso_dificil', 'Recargo por acceso difícil');
    sumar('recargo_producto', 'Recargo por producto del proveedor');
    return EstimacionServicio(
      precio: decimal(j['monto_estimado']),
      litros: hectareas * dosis,
      precioPorHectarea: decimal(
        j['tarifa_base_hectarea'] ?? j['tarifa_hectarea'],
      ),
      subtotal: j['subtotal_base'] == null ? null : decimal(j['subtotal_base']),
      recargos: recargos,
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
}
