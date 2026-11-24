// Dobles para probar las implementaciones de red del flavor cliente sin
// servidor: un adaptador de `dio` que responde según método y ruta, y los
// almacenes de token y dispositivo en memoria.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/cliente/red/cliente_http.dart';
import 'package:agrocom_field/cliente/red/fuente_solicitudes.dart';
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
    fuente = FuenteSolicitudes(http, ZonasRed(http));
  }

  final servidor = AdaptadorFalso();
  final TokenEnMemoria tokens;
  late final ApiClient api;
  late final ClienteHttp http;
  late final FuenteSolicitudes fuente;
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
  String estado = 'calificada',
  int? proveedorId = 1,
  int? ofertaAdjudicadaId = 14,
  String? precioAcordado = '124.0000',
  String? montoFinal = '7440.00',
  String? ejecutadas = '60.0000',
  String porcentaje = '100.00',
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
  'precio_ha_propuesto': '120.0000',
  'precio_ha_acordado': precioAcordado,
  'monto_estimado': '7440.00',
  'hectareas_ejecutadas': ejecutadas,
  'porcentaje_avance': porcentaje,
  'monto_final': montoFinal,
  'estado': estado,
  'oferta_adjudicada_id': ofertaAdjudicadaId,
  'proveedor_id': proveedorId,
  'vence_en': '2026-12-01T12:18:29+00:00',
  'publicada_en': '2026-11-24T12:18:29+00:00',
  'motivo_cancelacion': null,
  'cancelada_por': null,
  'terreno': terreno ?? terrenoJson(),
  'historial': ?historial,
};

/// Una oferta como la devuelve `GET /api/solicitudes/{id}/ofertas`.
Map<String, dynamic> ofertaJson({
  int id = 20,
  int solicitudId = 8,
  int numero = 1,
  String autor = 'proveedor',
  String tipo = 'acepta_propuesta',
  String precioHa = '120.0000',
  String estado = 'vigente',
  bool definitiva = false,
  String venceEn = '2026-11-25T06:00:00+00:00',
  String? nota,
  String nombre = 'Mamani Agroservicios',
}) => {
  'id': id,
  'uuid_cliente': 'a1b2c3d4-0000-4000-8000-00000000000$id',
  'solicitud_id': solicitudId,
  'proveedor_id': 2,
  'equipo_id': 3,
  'numero': numero,
  'autor': autor,
  'tipo': tipo,
  'precio_ha': precioHa,
  'monto_estimado': '7200.00',
  'estado': estado,
  'es_definitiva': definitiva,
  'nota': nota,
  'oferta_anterior_id': null,
  'distancia_km': '22.52',
  'vence_en': venceEn,
  'respondida_en': null,
  'creada_en': '2026-11-24T06:00:00+00:00',
  'proveedor': {
    'id': 2,
    'nombre': nombre,
    'calificacion_promedio': '4.50',
    'calificaciones_conteo': 8,
    'tasa_cancelacion': '0.1000',
    'dron': {
      'marca': 'DJI',
      'modelo': 'Agras T40',
      'anio': 2024,
      'capacidad_tanque_l': '40.00',
      'fotos': <Object>[],
    },
  },
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
