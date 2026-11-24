import 'dart:async';

import '../../nucleo/marketplace/dominio/dominio.dart';
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

/// Servicios del cliente leídos de la API, compartidos por los repositorios
/// de servicios, inicio, solicitud, calificación, conformidad y problema.
///
/// Es online-first: cada lectura va a la red y guarda en memoria lo último
/// conocido, que se muestra cuando falla la conexión. Quien escribe algo que
/// cambia un servicio llama [invalidar] y todas las pantallas se actualizan.
class FuenteServicios {
  FuenteServicios(this._http, this._zonas);

  final ClienteHttp _http;
  final ZonasRed _zonas;

  List<Servicio>? _cache;
  final _cambios = StreamController<List<Servicio>>.broadcast();

  /// Nombre del cliente de la sesión, para los servicios que se arman.
  String clienteNombre = 'Cliente';

  /// Puntaje y nombre del proveedor de servicios completados, que la lista no
  /// trae: salen de `GET /api/solicitudes/{id}/calificaciones` y no cambian
  /// una vez calificados.
  final _puntajes = <String, int>{};
  final _nombresProveedor = <String, String>{};

  Future<Map<int, ZonaCatalogo>> zonas() => _zonas.cargar();

  /// Todas las solicitudes (excepto borradores) del cliente, de la más
  /// reciente a la más antigua.
  Future<List<Servicio>> cargar() async {
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
    await Future.wait([
      for (final s in visibles)
        if (s['estado'] == 'completada') _conocerCalificacion('${s['id']}'),
    ]);
    final servicios = [for (final s in visibles) _armar(s, zonas)];
    _cache = servicios;
    return servicios;
  }

  Servicio _armar(Map<String, dynamic> crudo, Map<int, ZonaCatalogo> zonas) {
    final id = '${crudo['id']}';
    return MapeoSolicitud.servicio(
      crudo,
      zonas: zonas,
      puntajeDelCliente: _puntajes[id],
      nombreProveedor: _nombresProveedor[id],
      clienteNombre: clienteNombre,
    );
  }

  /// Lee a quién se calificó en un servicio completado y con cuántas
  /// estrellas. Un fallo del servidor no bloquea la lista; la falta de red
  /// sí, para no mostrar «sin calificar» por error.
  Future<void> _conocerCalificacion(String id) async {
    if (_puntajes.containsKey(id)) return;
    try {
      final r = await _http.obtener('/api/solicitudes/$id/calificaciones');
      final sujetos = r['sujetos'];
      if (sujetos is! List) return;
      for (final s in sujetos) {
        if (s is Map && s['tipo'] == 'proveedor') {
          _nombresProveedor[id] = '${s['nombre']}';
          final calificacion = s['calificacion'];
          if (calificacion is Map && calificacion['estrellas'] is int) {
            _puntajes[id] = calificacion['estrellas'] as int;
          }
        }
      }
    } on OperacionRechazada {
      return;
    }
  }

  /// Emite la lista y vuelve a emitir cuando algo cambia. Sin red, y con una
  /// lista ya conocida, muestra esa; sin lista, el error llega al `Stream`.
  Stream<List<Servicio>> observar() async* {
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
      throw const OperacionRechazada('No encontramos el servicio.');
    }
    return Map<String, dynamic>.from(s);
  }

  Future<Servicio> armar(Map<String, dynamic> crudo) async {
    final id = '${crudo['id']}';
    if (crudo['estado'] == 'completada') await _conocerCalificacion(id);
    return _armar(crudo, await _zonas.cargar());
  }

  /// El servicio [id], o `null` si no existe o no es del cliente (el
  /// servidor responde `404` en los dos casos).
  Future<Servicio?> detalle(String id) async {
    final r = await _http.obtenerOpcional('/api/solicitudes/$id');
    final s = r?['solicitud'];
    if (s is! Map) return null;
    return armar(Map<String, dynamic>.from(s));
  }

  /// Anota la calificación que el cliente acaba de dar.
  void registrarPuntaje(String id, int puntaje) => _puntajes[id] = puntaje;

  /// Algo cambió (solicitud nueva, calificación, conformidad): vuelve a leer
  /// y avisa a quienes observan. Un fallo se ignora; la próxima lectura lo
  /// vuelve a intentar.
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
    clienteNombre = 'Cliente';
  }
}
