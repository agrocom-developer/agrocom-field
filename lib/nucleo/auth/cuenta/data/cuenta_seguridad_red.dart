import 'package:dio/dio.dart' show Response;

import '../../../api/api_client.dart';
import '../../../api/api_excepcion.dart';
import '../../token_store.dart';
import '../domain/cuenta_seguridad.dart';

/// Seguridad de la cuenta contra la API (`/api/auth/recuperar*`,
/// `/api/auth/renovar`, `/api/cuenta/*`). Es en línea y sin outbox: la
/// persona espera la respuesta del servidor (ADR 0016).
class CuentaSeguridadRed implements CuentaSeguridadRepositorio {
  CuentaSeguridadRed({
    required ApiClient api,
    required TokenStore tokenStore,
    DateTime Function()? ahora,
  }) : _api = api,
       _tokenStore = tokenStore,
       _ahora = ahora ?? DateTime.now;

  final ApiClient _api;
  final TokenStore _tokenStore;
  final DateTime Function() _ahora;

  @override
  Future<void> pedirRecuperacion({
    required String identificador,
    required AppCuenta app,
    required CanalCodigo canal,
  }) async {
    await _llamar(
      () => _api.post(
        '/api/auth/recuperar',
        data: {
          'identificador': identificador.trim(),
          'app': app.codigo,
          'canal': canal.codigo,
        },
      ),
      canal: canal,
    );
  }

  @override
  Future<String> confirmarRecuperacion({
    required String identificador,
    required AppCuenta app,
    required String codigo,
    required String contrasenaNueva,
  }) async {
    final cuerpo = await _llamar(
      () => _api.post(
        '/api/auth/recuperar/confirmar',
        data: {
          'identificador': identificador.trim(),
          'app': app.codigo,
          'codigo': codigo.trim(),
          'password_nueva': contrasenaNueva,
        },
      ),
    );
    return '${cuerpo['username'] ?? ''}';
  }

  @override
  Future<CodigoEnviado> pedirCodigoContrasena(CanalCodigo canal) async {
    final c = await _llamar(
      () => _api.post(
        '/api/cuenta/contrasena/codigo',
        data: {'canal': canal.codigo},
      ),
      canal: canal,
    );
    return CodigoEnviado(destino: c['destino'] as String?);
  }

  @override
  Future<void> cambiarContrasena({
    required String codigo,
    required String contrasenaNueva,
  }) async {
    await _llamar(
      () => _api.put(
        '/api/cuenta/contrasena',
        data: {'codigo': codigo.trim(), 'password_nueva': contrasenaNueva},
      ),
    );
  }

  @override
  Future<CodigoEnviado> pedirCodigoTelefono(CanalCodigo canal) async {
    final c = await _llamar(
      () => _api.post(
        '/api/cuenta/telefono/verificacion',
        data: {'canal': canal.codigo},
      ),
      canal: canal,
    );
    return CodigoEnviado(destino: c['destino'] as String?);
  }

  @override
  Future<void> confirmarTelefono(String codigo) async {
    await _llamar(
      () => _api.post(
        '/api/cuenta/telefono/verificacion/confirmar',
        data: {'codigo': codigo.trim()},
      ),
    );
  }

  @override
  Future<PerfilSeguridad> perfil() async {
    final c = await _llamar(() => _api.get('/api/auth/sesion'));
    return _perfilDe(c);
  }

  PerfilSeguridad _perfilDe(Map<String, dynamic> cuerpo) {
    final usuario = cuerpo['usuario'];
    final dispositivo = cuerpo['dispositivo'];
    return PerfilSeguridad(
      telefonoVerificado:
          usuario is Map && usuario['telefono_verificado'] == true,
      fotoUrl: usuario is Map ? usuario['foto_url'] as String? : null,
      expiraEn: dispositivo is Map && dispositivo['expira_en'] is String
          ? DateTime.tryParse(dispositivo['expira_en'] as String)
          : null,
    );
  }

  @override
  Future<bool> renovarSiCorresponde({
    Duration margen = const Duration(days: 7),
  }) async {
    try {
      final actual = await perfil();
      final expira = actual.expiraEn;
      if (expira == null || expira.difference(_ahora()) > margen) return false;
      final c = await _llamar(() => _api.post('/api/auth/renovar'));
      final token = c['token'];
      if (token is! String || token.isEmpty) return false;
      // El anterior ya dejó de valer: se guarda el nuevo antes que nada.
      await _tokenStore.guardarToken(token);
      return true;
    } on Object {
      // Sin red o con un fallo del servidor la sesión sigue con el token
      // guardado; un `401` ya lo atendió el cliente HTTP (vuelve al ingreso).
      return false;
    }
  }

  @override
  Future<ConsultaEliminacion> consultarEliminacion() async {
    final c = await _llamar(() => _api.get('/api/cuenta/eliminacion'));
    return ConsultaEliminacion(
      eliminacion: _eliminacionDe(c['eliminacion']),
      impedimentos: _impedimentosDe(c['impedimentos']),
    );
  }

  @override
  Future<CodigoEnviado> pedirCodigoEliminacion(CanalCodigo canal) async {
    final c = await _llamar(
      () => _api.post(
        '/api/cuenta/eliminacion/codigo',
        data: {'canal': canal.codigo},
      ),
      canal: canal,
    );
    return CodigoEnviado(destino: c['destino'] as String?);
  }

  @override
  Future<EliminacionCuenta> eliminarCuenta({
    String? contrasena,
    String? codigo,
  }) async {
    final c = await _llamar(
      () => _api.post(
        '/api/cuenta/eliminacion',
        data: {'password': ?contrasena, 'codigo': ?codigo?.trim()},
      ),
    );
    return _eliminacionDe(c['eliminacion']) ?? _sinFecha();
  }

  @override
  Future<EliminacionCuenta> conservarCuenta() async {
    final c = await _llamar(
      () => _api.post('/api/cuenta/eliminacion/cancelar'),
    );
    return _eliminacionDe(c['eliminacion']) ?? _sinFecha();
  }

  EliminacionCuenta _sinFecha() => EliminacionCuenta(
    estado: EstadoEliminacion.solicitada,
    solicitadaEn: _ahora(),
    ejecutarDesde: _ahora().add(const Duration(days: 7)),
  );

  static EliminacionCuenta? _eliminacionDe(Object? json) {
    if (json is! Map) return null;
    final solicitada = DateTime.tryParse('${json['solicitada_en']}');
    final desde = DateTime.tryParse('${json['ejecutar_desde']}');
    if (solicitada == null || desde == null) return null;
    return EliminacionCuenta(
      estado: EstadoEliminacion.deCodigo(json['estado']),
      solicitadaEn: solicitada,
      ejecutarDesde: desde,
    );
  }

  static List<ImpedimentoEliminacion> _impedimentosDe(Object? json) => [
    if (json is List)
      for (final m in json) ?ImpedimentoEliminacion.deCodigo(m),
  ];

  /// Ejecuta [llamada] y traduce cualquier fallo a una [CuentaFalla].
  Future<Map<String, dynamic>> _llamar(
    Future<Response<dynamic>> Function() llamada, {
    CanalCodigo? canal,
  }) async {
    try {
      final r = await llamada();
      final datos = r.data;
      return datos is Map ? Map<String, dynamic>.from(datos) : {};
    } on ApiExcepcionRed {
      throw const CuentaSinConexion();
    } on ApiExcepcionServidor catch (e) {
      throw traducirFalla(e, canal: canal);
    } on ApiExcepcionDesconocida {
      throw const CuentaErrorDesconocido();
    }
  }

  /// Contrato de errores de las rutas de cuenta, en un solo lugar.
  static CuentaFalla traducirFalla(
    ApiExcepcionServidor e, {
    CanalCodigo? canal,
  }) {
    final cuerpo = e.cuerpo is Map ? e.cuerpo as Map : const {};
    final codigo = cuerpo['codigo'];
    switch (e.codigo) {
      case 401:
        return const CuentaSesionVencida();
      case 403 when codigo == 'cuenta_en_eliminacion':
        return const CuentaEnEliminacion();
      case 409 when codigo == 'telefono_ya_verificado':
        return const CuentaTelefonoYaVerificado();
      case 409 when codigo == 'eliminacion_bloqueada':
        return CuentaEliminacionBloqueada(_impedimentosDe(cuerpo['motivos']));
      case 422:
        return switch (codigo) {
          'codigo_invalido' => const CuentaCodigoInvalido(),
          'contrasena_incorrecta' => const CuentaContrasenaIncorrecta(),
          'sin_destino' => CuentaSinDestino(canal),
          _ => CuentaDatosInvalidos(
            mensaje: cuerpo['message'] as String?,
            porCampo: _errores(cuerpo['errors']),
          ),
        };
      case 429:
        return CuentaLimiteExcedido(espera: e.reintentarEn);
      case 503 when codigo == 'canal_no_disponible':
        return CuentaCanalNoDisponible(
          CanalCodigo.deCodigo(cuerpo['canal']) ?? canal,
        );
      default:
        return const CuentaErrorDesconocido();
    }
  }

  static Map<String, String> _errores(Object? json) {
    final salida = <String, String>{};
    if (json is Map) {
      json.forEach((campo, mensajes) {
        if (mensajes is List && mensajes.isNotEmpty) {
          salida['$campo'] = '${mensajes.first}';
        }
      });
    }
    return salida;
  }
}
