// La "otra mitad" del marketplace para los recorridos visuales: el cliente y
// el piloto son apps distintas, y cada recorrido corre una sola. Esta ayuda
// hace por la API, con las cuentas demo, lo que haría la contraparte (el
// piloto que oferta y ejecuta, o el cliente que publica y elige) para que la
// app bajo prueba tenga algo real que mostrar.
//
// Solo para pruebas de integración contra la API local; nunca se importa
// desde `lib/`.
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:agrocom_field/nucleo/entorno/api_base_url.dart';

const _uuid = Uuid();

/// Sesión de una cuenta demo contra la API real.
class Contraparte {
  Contraparte._(this._dio, this.usuario);

  final Dio _dio;
  final String usuario;

  /// Ingresa con [usuario] (contraseña demo `0000`). Si la cuenta tiene
  /// varios roles, elige [rol] (por ejemplo `proveedor` o `piloto`).
  static Future<Contraparte> ingresar(String usuario, {String? rol}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        headers: {'Accept': 'application/json'},
        validateStatus: (_) => true,
      ),
    );
    Future<Response<dynamic>> pedir([int? rolId]) => dio.post(
      '/api/auth/token',
      data: {
        'username': usuario,
        'password': '0000',
        'uuid_dispositivo': _uuid.v4(),
        'nombre_dispositivo': 'Recorrido visual',
        'role_id': ?rolId,
      },
    );

    var r = await pedir();
    if (r.statusCode == 409 && rol != null) {
      final roles = (r.data as Map)['roles'] as List;
      final elegido = roles.cast<Map>().firstWhere((x) => x['name'] == rol);
      r = await pedir(elegido['id'] as int);
    }
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw StateError('Ingreso de $usuario falló: ${r.statusCode} ${r.data}');
    }
    dio.options.headers['Authorization'] = 'Bearer ${(r.data as Map)['token']}';
    return Contraparte._(dio, usuario);
  }

  Future<Map<String, dynamic>> _ok(Response<dynamic> r, String ruta) async {
    if (r.statusCode == null || r.statusCode! >= 300) {
      throw StateError('$usuario $ruta: ${r.statusCode} ${r.data}');
    }
    return r.data is Map ? Map<String, dynamic>.from(r.data as Map) : {};
  }

  Future<Map<String, dynamic>> obtener(String ruta) async =>
      _ok(await _dio.get(ruta), 'GET $ruta');

  Future<Map<String, dynamic>> enviar(String ruta, [Object? datos]) async =>
      _ok(await _dio.post(ruta, data: datos), 'POST $ruta');

  Future<Map<String, dynamic>> poner(String ruta, Object datos) async =>
      _ok(await _dio.put(ruta, data: datos), 'PUT $ruta');

  // ---- Cliente ----------------------------------------------------------

  /// Crea y publica una solicitud sobre el primer terreno del cliente.
  /// Devuelve su id.
  Future<int> publicarSolicitud({
    required String precioHa,
    required String hectareas,
    String observaciones = 'Recorrido visual',
  }) async {
    final terreno = ((await obtener('/api/terrenos'))['terrenos'] as List)
        .cast<Map>()
        .first;
    final hoy = DateTime.now().add(const Duration(days: 3));
    String dia(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final creada = await enviar('/api/solicitudes', {
      'uuid_cliente': _uuid.v4(),
      'terreno_id': terreno['id'],
      'tipo_aplicacion': 'insecticida',
      'hectareas_solicitadas': hectareas,
      'cultivo': terreno['cultivo'],
      'producto_indicado': 'Insecticida piretroide',
      'aporta_producto': 'cliente',
      'ventana_desde': dia(hoy),
      'ventana_hasta': dia(hoy.add(const Duration(days: 3))),
      'urgente': false,
      'observaciones': observaciones,
      'precio_ha_propuesto': precioHa,
    });
    final id = (creada['solicitud'] as Map)['id'] as int;
    await enviar('/api/solicitudes/$id/publicar');
    return id;
  }

  /// Acepta la oferta indicada (como cliente). Devuelve la respuesta.
  Future<Map<String, dynamic>> aceptarOferta(int ofertaId) =>
      enviar('/api/ofertas/$ofertaId/aceptar');

  Future<void> calificar(int solicitudId, {int estrellas = 5}) async {
    await enviar('/api/solicitudes/$solicitudId/calificaciones', {
      'calificaciones': [
        {
          'uuid_cliente': _uuid.v4(),
          'sujeto_tipo': 'proveedor',
          'estrellas': estrellas,
          'etiquetas': <String>[],
        },
      ],
    });
  }

  // ---- Proveedor --------------------------------------------------------

  /// Oferta sobre una solicitud abierta. Sin [precioHa] acepta la propuesta
  /// del cliente; con él, contraoferta. Devuelve el id de la oferta.
  Future<int> ofertar(int solicitudId, {String? precioHa, String? nota}) async {
    final r = await enviar('/api/solicitudes/$solicitudId/ofertas', {
      'uuid_cliente': _uuid.v4(),
      'tipo': precioHa == null ? 'acepta_propuesta' : 'contraoferta',
      'precio_ha': ?precioHa,
      'nota': ?nota,
    });
    return (r['oferta'] as Map)['id'] as int;
  }

  Future<void> iniciarServicio(int solicitudId) async {
    await enviar('/api/solicitudes/$solicitudId/inicio', {
      'uuid_cliente': _uuid.v4(),
    });
  }

  Future<void> marcarAvance(int solicitudId, String porcentaje) async {
    await enviar('/api/solicitudes/$solicitudId/avance', {
      'uuid_cliente': _uuid.v4(),
      'porcentaje': porcentaje,
    });
  }

  /// Sube una foto (de los recursos de la app) como evidencia del servicio.
  Future<void> subirFoto(
    int solicitudId, {
    String tipo = 'foto_avance',
    String recurso = 'assets/imagenes/fondo_dron_pulverizando.jpg',
  }) async {
    final bytes = (await rootBundle.load(recurso)).buffer.asUint8List();
    await _ok(
      await _dio.post(
        '/api/solicitudes/$solicitudId/evidencias',
        data: FormData.fromMap({
          'uuid_cliente': _uuid.v4(),
          'tipo': tipo,
          'archivo': MultipartFile.fromBytes(bytes, filename: 'foto.jpg'),
        }),
      ),
      'evidencias',
    );
  }

  Future<void> enviarUbicacion(int solicitudId, double lat, double lon) async {
    await poner('/api/ubicacion', {
      'solicitud_id': solicitudId,
      'latitud': lat,
      'longitud': lon,
      'precision_m': 8,
    });
  }

  Future<void> escribir(int solicitudId, String texto) async {
    await enviar('/api/solicitudes/$solicitudId/mensajes', {
      'uuid_cliente': _uuid.v4(),
      'texto': texto,
    });
  }

  Future<void> cerrarServicio(int solicitudId, String hectareas) async {
    await enviar('/api/solicitudes/$solicitudId/cierre', {
      'uuid_cliente': _uuid.v4(),
      'hectareas_ejecutadas': hectareas,
    });
  }
}
