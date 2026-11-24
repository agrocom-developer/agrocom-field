import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../../red/mapeo_solicitud.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/reglas_solicitud.dart';
import '../domain/solicitud_repositorio.dart';

/// Publicación de solicitudes contra la API.
///
/// Crea un borrador (`POST /api/solicitudes`, con el precio por hectárea que
/// propone el cliente) y lo abre a los pilotos (`POST
/// /api/solicitudes/{id}/publicar`). El `uuid_cliente` del borrador se deriva
/// de la clave de idempotencia y de lo escrito: reintentar no crea otro, y
/// cambiar un dato crea un borrador nuevo. Los borradores no se muestran en
/// el historial.
class SolicitudRed implements SolicitudRepositorio {
  SolicitudRed(
    this._http,
    this._fuente, {
    Uuid? uuid,
    DateTime Function()? reloj,
  }) : _uuid = uuid ?? const Uuid(),
       _reloj = reloj ?? DateTime.now;

  final ClienteHttp _http;
  final FuenteSolicitudes _fuente;
  final Uuid _uuid;
  final DateTime Function() _reloj;

  /// Terrenos que esta sesión creó a partir de un contorno dibujado, por el
  /// id local del lote, para no crear dos veces el mismo.
  final _terrenosCreados = <String, int>{};

  static const _productos = [
    'Glifosato 480 SL + coadyuvante',
    'Fungicida triazol + estrobilurina',
    'Insecticida piretroide',
    'Herbicida de preemergencia',
    'Fertilizante foliar',
  ];

  static const _cultivos = [
    'Soya',
    'Maíz',
    'Girasol',
    'Trigo',
    'Sorgo',
    'Arroz',
    'Caña de azúcar',
  ];

  /// Cuántos días después de la fecha deseada se sigue aceptando el trabajo.
  static const _diasDeVentana = 3;

  @override
  Future<List<Lote>> lotesDelCliente() async {
    final zonas = await _fuente.zonas();
    final r = await _http.obtener('/api/terrenos');
    final terrenos = r['terrenos'];
    if (terrenos is! List) return const [];
    return [
      for (final t in terrenos)
        if (t is Map)
          MapeoSolicitud.lote(Map<String, dynamic>.from(t), zonas: zonas),
    ];
  }

  // El servidor no tiene un catálogo de productos ni de cultivos: son
  // sugerencias fijas para no teclear (ver `docs/gestion/brechas-api.md`).
  @override
  Future<List<String>> productosSugeridos() async => _productos;

  @override
  Future<List<String>> cultivosSugeridos() async => _cultivos;

  @override
  Future<Solicitud> publicar(NuevaSolicitud s) async {
    try {
      final id = await _asegurarBorrador(s);
      Map<String, dynamic> crudo;
      try {
        final r = await _http.enviar('/api/solicitudes/$id/publicar');
        crudo = Map<String, dynamic>.from(r['solicitud'] as Map);
      } on OperacionRechazada {
        // Un reintento después de que la primera publicación sí llegó: el
        // servidor ya no la deja publicar, pero la solicitud existe.
        crudo = await _fuente.crudo('$id');
        if (crudo['estado'] == 'borrador') rethrow;
      }
      final solicitud = await _fuente.armar(crudo);
      unawaited(_fuente.invalidar());
      return solicitud;
    } on SinConexion {
      throw const SolicitudSinConexion();
    }
  }

  Future<int> _asegurarBorrador(NuevaSolicitud s) async {
    final desde = s.fechaDeseada;
    final hasta = DateTime(desde.year, desde.month, desde.day + _diasDeVentana);
    final huella =
        '${s.claveIdempotencia}|${s.lote.id}|${s.hectareas}|${s.producto}|'
        '${s.cultivo}|${MapeoSolicitud.diaApi(desde)}|${s.precioHa}|'
        '${s.observaciones}';
    final terrenoId = await _terrenoDe(s.lote, s.accesos);
    final r = await _http.enviar(
      '/api/solicitudes',
      datos: {
        'uuid_cliente': _uuid.v5(Namespace.url.value, huella),
        'terreno_id': terrenoId,
        'tipo_aplicacion': MapeoSolicitud.tipoAplicacion(s.producto),
        'hectareas_solicitadas': '${s.hectareas}',
        if (s.cultivo.isNotEmpty) 'cultivo': s.cultivo,
        'producto_indicado': s.producto,
        'aporta_producto': 'cliente',
        'ventana_desde': MapeoSolicitud.diaApi(desde),
        'ventana_hasta': MapeoSolicitud.diaApi(hasta),
        'urgente': ReglasSolicitud.esUrgente(desde, _reloj()),
        'observaciones': ?s.observaciones,
        'precio_ha_propuesto': '${s.precioHa}',
      },
    );
    final creada = r['solicitud'];
    if (creada is! Map || creada['id'] is! int) {
      throw const OperacionRechazada('No pudimos preparar tu solicitud.');
    }
    return creada['id'] as int;
  }

  /// El terreno de la solicitud: el guardado, o uno nuevo que se crea con el
  /// contorno dibujado (`POST /api/terrenos`).
  Future<int> _terrenoDe(Lote lote, String? accesos) async {
    final guardado = int.tryParse(lote.id);
    if (guardado != null) return guardado;
    final creado = _terrenosCreados[lote.id];
    if (creado != null) return creado;
    final r = await _http.enviar(
      '/api/terrenos',
      datos: {
        'nombre': lote.nombre,
        'hectareas': '${lote.hectareas}',
        if (lote.cultivo.isNotEmpty) 'cultivo': lote.cultivo,
        'geometria': MapeoSolicitud.geoJson(lote.poligono),
        'referencias_acceso': ?accesos,
      },
    );
    final t = r['terreno'];
    if (t is! Map || t['id'] is! int) {
      throw const OperacionRechazada('No pudimos guardar el terreno.');
    }
    return _terrenosCreados[lote.id] = t['id'] as int;
  }
}
