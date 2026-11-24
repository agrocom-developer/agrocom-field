import 'dart:async';

import '../../nucleo/marketplace/dominio/dominio.dart';
import '../solicitudes/domain/solicitud.dart';
import 'cliente_http.dart';
import 'mapeo_solicitud.dart';

/// Catálogo de zonas (`GET /api/zonas`, sin autenticación). Se pide una vez y
/// se reutiliza: sirve para ponerle nombre a la zona de cada terreno.
class ZonasRed {
  ZonasRed(this._http);

  final ClienteHttp _http;
  Map<int, ZonaCatalogo>? _cache;

  /// Si el catálogo no responde, devuelve un mapa vacío: el terreno se
  /// muestra «Sin zona asignada» en vez de bloquear la pantalla.
  Future<Map<int, ZonaCatalogo>> cargar() async {
    final previo = _cache;
    if (previo != null) return previo;
    try {
      final r = await _http.obtener('/api/zonas');
      final zonas = <int, ZonaCatalogo>{};
      final datos = r['data'];
      if (datos is List) {
        for (final z in datos) {
          if (z is! Map || z['id'] is! int) continue;
          final lat = double.tryParse('${z['centroide_lat']}');
          final lng = double.tryParse('${z['centroide_lng']}');
          if (lat == null || lng == null) continue;
          zonas[z['id'] as int] = ZonaCatalogo(
            id: z['id'] as int,
            nombre: '${z['nombre']}',
            centro: GeoPunto(lat, lng),
          );
        }
      }
      return _cache = zonas;
    } on FallaMarketplace {
      return const {};
    }
  }
}

/// Solicitudes del cliente leídas de la API, compartidas por los
/// repositorios de solicitudes, inicio, calificación y disputa.
///
/// Es online-first: cada lectura va a la red y guarda en memoria lo último
/// conocido, que se muestra cuando falla la conexión. Quien escribe algo que
/// cambia una solicitud llama [invalidar] y todas las pantallas se
/// actualizan.
class FuenteSolicitudes {
  FuenteSolicitudes(this._http, this._zonas);

  final ClienteHttp _http;
  final ZonasRed _zonas;

  List<Solicitud>? _cache;
  final _cambios = StreamController<List<Solicitud>>.broadcast();

  /// Estrellas y nombre del piloto de las solicitudes ya conocidas: no
  /// cambian una vez calificadas o adjudicadas.
  final _puntajes = <String, int>{};
  final _nombresProveedor = <String, String>{};

  Future<Map<int, ZonaCatalogo>> zonas() => _zonas.cargar();

  /// Todas las solicitudes (excepto borradores) del cliente, de la más
  /// reciente a la más antigua.
  Future<List<Solicitud>> cargar() async {
    final zonas = await _zonas.cargar();
    final crudos = <Map<String, dynamic>>[];
    var pagina = 1;
    var paginas = 1;
    do {
      final r = await _http.obtener(
        '/api/solicitudes',
        query: {'page': pagina},
      );
      final lista = r['solicitudes'];
      if (lista is List) {
        crudos.addAll([
          for (final s in lista)
            if (s is Map) Map<String, dynamic>.from(s),
        ]);
      }
      paginas = (r['paginas'] as int?) ?? 1;
      pagina++;
    } while (pagina <= paginas);

    final visibles = [
      for (final s in crudos)
        if (s['estado'] != 'borrador') s,
    ];
    final conteos = <String, int>{};
    await Future.wait([
      for (final s in visibles) ...[
        if (s['estado'] == 'calificada') _conocerCalificacion('${s['id']}'),
        if (s['oferta_adjudicada_id'] != null)
          _conocerProveedor('${s['id']}', '${s['oferta_adjudicada_id']}'),
        if (s['estado'] == 'abierta' || s['estado'] == 'con_ofertas')
          _contarOfertas('${s['id']}', conteos),
      ],
    ]);
    final solicitudes = [
      for (final s in visibles) _armar(s, zonas, conteos['${s['id']}']),
    ];
    _cache = solicitudes;
    return solicitudes;
  }

  Solicitud _armar(
    Map<String, dynamic> crudo,
    Map<int, ZonaCatalogo> zonas, [
    int? ofertasVigentes,
  ]) {
    final id = '${crudo['id']}';
    return MapeoSolicitud.solicitud(
      crudo,
      zonas: zonas,
      puntajeDelCliente: _puntajes[id],
      nombreProveedor: _nombresProveedor[id],
      ofertasVigentes: ofertasVigentes,
    );
  }

  /// Un fallo del servidor no bloquea la lista; la falta de red sí, para no
  /// mostrar «sin calificar» o «sin piloto» por error.
  Future<void> _tolerar(Future<void> Function() accion) async {
    try {
      await accion();
    } on OperacionRechazada {
      return;
    }
  }

  Future<void> _conocerCalificacion(String id) => _tolerar(() async {
    if (_puntajes.containsKey(id)) return;
    final r = await _http.obtener('/api/solicitudes/$id/calificaciones');
    final sujetos = r['sujetos'];
    if (sujetos is! List) return;
    for (final s in sujetos) {
      if (s is Map && s['tipo'] == 'proveedor') {
        final calificacion = s['calificacion'];
        if (calificacion is Map && calificacion['estrellas'] is int) {
          _puntajes[id] = calificacion['estrellas'] as int;
        }
      }
    }
  });

  Future<void> _conocerProveedor(String id, String ofertaId) =>
      _tolerar(() async {
        if (_nombresProveedor.containsKey(id)) return;
        final r = await _http.obtener('/api/ofertas/$ofertaId');
        final oferta = r['oferta'];
        if (oferta is! Map) return;
        final proveedor = oferta['proveedor'];
        if (proveedor is Map && proveedor['nombre'] is String) {
          _nombresProveedor[id] = proveedor['nombre'] as String;
        }
      });

  Future<void> _contarOfertas(String id, Map<String, int> conteos) =>
      _tolerar(() async {
        final r = await _http.obtener('/api/solicitudes/$id/ofertas');
        final ofertas = r['ofertas'];
        if (ofertas is! List) return;
        conteos[id] = ofertas
            .where((o) => o is Map && o['estado'] == 'vigente')
            .length;
      });

  /// Emite la lista y vuelve a emitir cuando algo cambia. Sin red, y con una
  /// lista ya conocida, muestra esa; sin lista, el error llega al `Stream`.
  Stream<List<Solicitud>> observar() async* {
    try {
      yield await cargar();
    } on SinConexion {
      final previo = _cache;
      if (previo == null) rethrow;
      yield previo;
    }
    yield* _cambios.stream;
  }

  /// La solicitud tal como la devuelve el servidor, con su historial.
  Future<Map<String, dynamic>> crudo(String id) async {
    final r = await _http.obtener('/api/solicitudes/$id');
    final s = r['solicitud'];
    if (s is! Map) {
      throw const OperacionRechazada('No encontramos la solicitud.');
    }
    return Map<String, dynamic>.from(s);
  }

  Future<Solicitud> armar(Map<String, dynamic> crudo) async {
    final id = '${crudo['id']}';
    if (crudo['estado'] == 'calificada') await _conocerCalificacion(id);
    if (crudo['oferta_adjudicada_id'] != null) {
      await _conocerProveedor(id, '${crudo['oferta_adjudicada_id']}');
    }
    return _armar(crudo, await _zonas.cargar());
  }

  /// La solicitud [id], o `null` si no existe o no es del cliente (el
  /// servidor responde `404` en los dos casos).
  Future<Solicitud?> detalle(String id) async {
    final r = await _http.obtenerOpcional('/api/solicitudes/$id');
    final s = r?['solicitud'];
    if (s is! Map) return null;
    return armar(Map<String, dynamic>.from(s));
  }

  /// Anota la calificación que el cliente acaba de dar.
  void registrarPuntaje(String id, int puntaje) => _puntajes[id] = puntaje;

  /// Algo cambió (solicitud nueva, oferta aceptada, calificación): vuelve a
  /// leer y avisa a quienes observan. Un fallo se ignora; la próxima lectura
  /// lo vuelve a intentar.
  Future<void> invalidar() async {
    try {
      final lista = await cargar();
      if (!_cambios.isClosed) _cambios.add(lista);
    } on FallaMarketplace {
      return;
    }
  }

  /// Descarta todo lo guardado: se llama al cerrar sesión para que el
  /// próximo usuario no vea datos ajenos.
  void olvidar() {
    _cache = null;
    _puntajes.clear();
    _nombresProveedor.clear();
  }
}
