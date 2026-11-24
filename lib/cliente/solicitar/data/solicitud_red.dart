import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_servicios.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/reglas_solicitud.dart';
import '../domain/solicitud_repositorio.dart';

/// Solicitud de servicios contra la API.
///
/// La tarifa solo se calcula sobre una solicitud ya creada
/// (`GET /api/solicitudes/{id}/estimacion`), así que [estimar] crea un
/// borrador y [solicitar] publica ese mismo borrador (`POST
/// /api/solicitudes/{id}/publicar`). El `uuid_cliente` del borrador se
/// deriva de la clave de idempotencia y de lo escrito: reintentar no crea
/// otro, y cambiar un dato crea un borrador nuevo. Los borradores no se
/// muestran en el historial.
class SolicitudRed implements SolicitudRepositorio {
  SolicitudRed(
    this._http,
    this._fuente, {
    Uuid? uuid,
    DateTime Function()? reloj,
    this.pasoBusqueda = const Duration(seconds: 4),
  }) : _uuid = uuid ?? const Uuid(),
       _reloj = reloj ?? DateTime.now;

  final ClienteHttp _http;
  final FuenteServicios _fuente;
  final Uuid _uuid;
  final DateTime Function() _reloj;

  /// Cada cuánto se vuelve a leer el avance de la asignación.
  final Duration pasoBusqueda;

  /// Terrenos que esta sesión creó a partir de un contorno dibujado, por el
  /// id local del lote, para no crear dos veces el mismo.
  final _terrenosCreados = <String, int>{};

  /// Último borrador creado y la huella de los datos con que se creó.
  _Borrador? _borrador;

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
  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
    Decimal? hectareas,
    DateTime? fechaDeseada,
    String? producto,
    String? cultivo,
    VentanaHoraria ventana = VentanaHoraria.indistinta,
    String? claveIdempotencia,
  }) async {
    final solicitud = SolicitudServicio(
      lote: lote,
      producto: producto ?? 'Producto por definir',
      dosisLitrosPorHectarea: dosisLitrosPorHectarea,
      fechaDeseada:
          fechaDeseada ??
          _reloj().add(const Duration(days: ReglasSolicitud.diasUrgencia)),
      claveIdempotencia: claveIdempotencia ?? _uuid.v4(),
      hectareas: hectareas,
      cultivo: cultivo,
      ventana: ventana,
    );
    final borrador = await _asegurarBorrador(solicitud);
    final r = await _http.obtener('/api/solicitudes/${borrador.id}/estimacion');
    final e = r['estimacion'];
    if (e is! Map) {
      throw const OperacionRechazada('No pudimos calcular el precio.');
    }
    return MapeoSolicitud.estimacion(
      Map<String, dynamic>.from(e),
      dosis: dosisLitrosPorHectarea,
      hectareas: solicitud.hectareas,
    );
  }

  @override
  Future<Servicio> solicitar(SolicitudServicio solicitud) async {
    try {
      final borrador = await _asegurarBorrador(solicitud);
      Map<String, dynamic> crudo;
      try {
        final r = await _http.enviar(
          '/api/solicitudes/${borrador.id}/publicar',
        );
        crudo = Map<String, dynamic>.from(r['solicitud'] as Map);
      } on OperacionRechazada {
        // Un reintento después de que la primera publicación sí llegó: el
        // servidor ya no la deja publicar, pero la solicitud existe.
        crudo = await _fuente.crudo('${borrador.id}');
        if (crudo['estado'] == 'borrador') rethrow;
      }
      final servicio = await _fuente.armar(crudo);
      _borrador = null;
      unawaited(_fuente.invalidar());
      return servicio;
    } on SinConexion {
      throw const SolicitudSinConexion();
    }
  }

  /// Avance de la asignación leyendo la solicitud cada [pasoBusqueda]. La
  /// API no distingue la ronda de propios de la de terceros: mientras se
  /// busca, se muestra la primera.
  @override
  Stream<BusquedaProveedor> observarBusqueda(String servicioId) async* {
    while (true) {
      final crudo = await _fuente.crudo(servicioId);
      final servicio = await _fuente.armar(crudo);
      final busqueda = switch (crudo['estado']) {
        'sin_proveedor' ||
        'cancelada' => const BusquedaProveedor(fase: FaseBusqueda.sinProveedor),
        _ when servicio.estado != EstadoServicio.buscandoProveedor =>
          BusquedaProveedor(
            fase: FaseBusqueda.asignado,
            proveedor: servicio.proveedor,
          ),
        _ => const BusquedaProveedor(fase: FaseBusqueda.propios),
      };
      yield busqueda;
      if (busqueda.terminada) return;
      await Future<void>.delayed(pasoBusqueda);
    }
  }

  Future<_Borrador> _asegurarBorrador(SolicitudServicio s) async {
    final fecha = s.fechaDeseada;
    final dia =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    final huella =
        '${s.claveIdempotencia}|${s.lote.id}|${s.hectareas}|'
        '${s.dosisLitrosPorHectarea}|${s.producto}|${s.cultivo}|$dia|'
        '${s.ventana.name}';
    final previo = _borrador;
    if (previo != null && previo.huella == huella) return previo;

    final terrenoId = await _terrenoDe(s.lote);
    final hasta = DateTime(fecha.year, fecha.month, fecha.day + 7);
    final r = await _http.enviar(
      '/api/solicitudes',
      datos: {
        'uuid_cliente': _uuid.v5(Namespace.url.value, huella),
        'terreno_id': terrenoId,
        'tipo_aplicacion': MapeoSolicitud.tipoAplicacion(s.producto),
        'hectareas_solicitadas': '${s.hectareas}',
        if (s.cultivo.isNotEmpty) 'cultivo': s.cultivo,
        'producto_indicado': MapeoSolicitud.productoIndicado(
          s.producto,
          s.dosisLitrosPorHectarea,
        ),
        'aporta_producto': 'cliente',
        'ventana_desde': dia,
        'ventana_hasta':
            '${hasta.year}-${hasta.month.toString().padLeft(2, '0')}-'
            '${hasta.day.toString().padLeft(2, '0')}',
        'urgente': ReglasSolicitud.esUrgente(fecha, _reloj()),
        if (s.ventana != VentanaHoraria.indistinta)
          'observaciones':
              'Horario preferido: ${s.ventana.etiqueta} (${s.ventana.horario}).',
      },
    );
    final creada = r['solicitud'];
    if (creada is! Map || creada['id'] is! int) {
      throw const OperacionRechazada('No pudimos preparar tu solicitud.');
    }
    return _borrador = _Borrador(huella, creada['id'] as int);
  }

  /// El terreno de la solicitud: el guardado, o uno nuevo que se crea con el
  /// contorno dibujado (`POST /api/terrenos`).
  Future<int> _terrenoDe(Lote lote) async {
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
      },
    );
    final t = r['terreno'];
    if (t is! Map || t['id'] is! int) {
      throw const OperacionRechazada('No pudimos guardar el terreno.');
    }
    return _terrenosCreados[lote.id] = t['id'] as int;
  }
}

class _Borrador {
  const _Borrador(this.huella, this.id);

  final String huella;
  final int id;
}
