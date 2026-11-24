// Dobles para probar las implementaciones de red del flavor cliente sin
// servidor: un adaptador de `dio` que responde según método y ruta, y los
// almacenes de token y dispositivo en memoria.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/cliente/red/cliente_http.dart';
import 'package:agrocom_field/cliente/red/fuente_servicios.dart';
import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/auth/dispositivo_store.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:dio/dio.dart';

/// Una petición que llegó al servidor falso.
class Peticion {
  Peticion(this.metodo, this.ruta, this.cuerpo, this.query, this.token);

  final String metodo;
  final String ruta;
  final Object? cuerpo;
  final Map<String, dynamic> query;
  final String? token;
}

/// Servidor falso: responde con lo que cada test registra con [responder] y
/// guarda todas las peticiones recibidas.
class AdaptadorFalso implements HttpClientAdapter {
  final _respuestas = <String, _Respuesta>{};
  final peticiones = <Peticion>[];

  /// Con `true`, toda petición falla como si no hubiera red.
  bool sinRed = false;

  /// Registra la respuesta de `METODO /ruta`. Un [cuerpo] `List` de
  /// respuestas se consume en orden (la última se repite).
  void responder(
    String metodo,
    String ruta, {
    int codigo = 200,
    Object? cuerpo,
    List<Object?>? secuencia,
  }) {
    _respuestas['$metodo $ruta'] = _Respuesta(codigo, cuerpo, secuencia);
  }

  Iterable<Peticion> de(String metodo, String ruta) =>
      peticiones.where((p) => p.metodo == metodo && p.ruta == ruta);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (sinRed) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    peticiones.add(
      Peticion(
        options.method,
        options.path,
        options.data,
        options.queryParameters,
        options.headers['Authorization'] as String?,
      ),
    );
    final r = _respuestas['${options.method} ${options.path}'];
    final (codigo, cuerpo) = r == null
        ? (404, <String, Object>{})
        : r.siguiente();
    return ResponseBody.fromString(
      jsonEncode(cuerpo),
      codigo,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Respuesta {
  _Respuesta(this.codigo, this.cuerpo, this.secuencia);

  final int codigo;
  final Object? cuerpo;
  final List<Object?>? secuencia;
  int _i = 0;

  (int, Object?) siguiente() {
    final s = secuencia;
    if (s == null || s.isEmpty) return (codigo, cuerpo);
    final valor = s[_i < s.length - 1 ? _i++ : s.length - 1];
    // Un elemento `(codigo, cuerpo)` cambia también el código de esa respuesta.
    if (valor is (int, Object?)) return valor;
    return (codigo, valor);
  }
}

class TokenEnMemoria implements TokenStore {
  TokenEnMemoria([this.token]);

  String? token;

  @override
  Future<String?> leerToken() async => token;

  @override
  Future<void> guardarToken(String nuevo) async => token = nuevo;

  @override
  Future<void> borrarToken() async => token = null;
}

class DispositivoFijo implements DispositivoStore {
  @override
  Future<String> obtenerUuidDispositivo() async =>
      '11111111-1111-4111-8111-111111111111';
}

/// Todo lo necesario para probar un repositorio de red.
class EntornoRed {
  EntornoRed({String? token = 'tok'}) : tokens = TokenEnMemoria(token) {
    api = ApiClient(
      baseUrl: 'http://api.prueba',
      tokenStore: tokens,
      dio: Dio(BaseOptions(baseUrl: 'http://api.prueba'))
        ..httpClientAdapter = servidor,
    );
    http = ClienteHttp(api);
    fuente = FuenteServicios(http, ZonasRed(http));
  }

  final servidor = AdaptadorFalso();
  final TokenEnMemoria tokens;
  late final ApiClient api;
  late final ClienteHttp http;
  late final FuenteServicios fuente;
}

// ── Cuerpos de ejemplo, con la forma de `docs/api/openapi.yaml` ──────────

Map<String, dynamic> terrenoJson({
  int id = 1,
  String hectareas = '80.0000',
  Object? geometria,
  int? zonaId = 6,
}) => {
  'id': id,
  'nombre': 'Lote Norte',
  'hectareas': hectareas,
  'cultivo': 'Soya',
  'geometria': geometria,
  'referencias_acceso': null,
  'colindantes_sensibles': null,
  'acceso_dificil': false,
  'zona_id': zonaId,
};

Map<String, dynamic> solicitudJson({
  int id = 8,
  String estado = 'completada',
  int? proveedorId = 1,
  String? montoFinal = '7200.00',
  List<Map<String, dynamic>>? historial,
  Map<String, dynamic>? terreno,
}) => {
  'id': id,
  'uuid_cliente': '8655660e-6125-5879-b05b-d8b57221d25c',
  'terreno_id': 1,
  'tipo_aplicacion': 'herbicida',
  'hectareas_solicitadas': '60.0000',
  'cultivo': 'Soya',
  'producto_indicado': 'Glifosato 480 SL, 2 L/ha',
  'aporta_producto': 'cliente',
  'ventana_desde': '2026-11-27',
  'ventana_hasta': '2026-12-06',
  'urgente': false,
  'observaciones': null,
  'tarifa_hectarea': '120.0000',
  'monto_estimado': '7200.00',
  'monto_final': montoFinal,
  'estado': estado,
  'proveedor_id': proveedorId,
  'publicada_en': '2026-11-24T12:18:29+00:00',
  'motivo_cancelacion': null,
  'cancelada_por': null,
  'terreno': terreno ?? terrenoJson(),
  'historial': ?historial,
};

Map<String, dynamic> pasoHistorial(String estado, String cuando) => {
  'estado_anterior': null,
  'estado_nuevo': estado,
  'origen': 'sistema',
  'motivo': null,
  'creado_en': cuando,
};

const zonasJson = {
  'data': [
    {
      'id': 6,
      'nombre': 'Cuatro Cañadas',
      'centroide_lat': '-17.3583000',
      'centroide_lng': '-62.5667000',
      'radio_km': '45.0',
    },
  ],
};

Map<String, dynamic> calificacionesJson({
  Map<String, dynamic>? calificacion,
  bool puede = true,
}) => {
  'puede_calificar': puede,
  'vence_en': '2026-12-01T12:18:30+00:00',
  'plazo_dias': 7,
  'sujetos': [
    {
      'tipo': 'proveedor',
      'id': 1,
      'nombre': 'Agrocom SRL',
      'calificacion': calificacion,
    },
    {
      'tipo': 'piloto',
      'id': 1,
      'nombre': 'Rodrigo Suárez Peña',
      'calificacion': null,
    },
  ],
  'etiquetas': ['puntualidad'],
};
