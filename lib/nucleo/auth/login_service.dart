import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import 'dispositivo_store.dart';
import 'persona_operativa_store.dart';
import 'resultado_login.dart';
import 'rol_activo.dart';
import 'rol_activo_store.dart';
import 'token_store.dart';

/// Caso de uso de HU-03: intercambia usuario/contraseña por el token de
/// dispositivo (`POST /api/auth/token`, operationId
/// `emitirTokenDispositivo`) y lo persiste con [TokenStore.guardarToken].
/// También persiste `usuario.persona_id` (HU-05: lo necesita
/// `AperturaSesion.piloto_id`) con [PersonaOperativaStore] — nullable, así
/// que un usuario sin persona operativa enlazada queda con `null` guardado,
/// nunca con un valor de un login anterior — y el `rol` del `201` con
/// [RolActivoStore] (ADR 0005 de este repo).
///
/// Acepta [roleId] opcional (`role_id` en el body) para reintentar el login
/// una vez elegido un rol tras un `409` — ver [LoginRolAmbiguo].
class LoginService {
  LoginService({
    required ApiClient apiClient,
    required TokenStore tokenStore,
    required DispositivoStore dispositivoStore,
    required PersonaOperativaStore personaOperativaStore,
    required RolActivoStore rolActivoStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _dispositivoStore = dispositivoStore,
       _personaOperativaStore = personaOperativaStore,
       _rolActivoStore = rolActivoStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final DispositivoStore _dispositivoStore;
  final PersonaOperativaStore _personaOperativaStore;
  final RolActivoStore _rolActivoStore;

  Future<ResultadoLogin> login({
    required String usuario,
    required String contrasena,
    int? roleId,
  }) async {
    final uuidDispositivo = await _dispositivoStore.obtenerUuidDispositivo();

    final Response<dynamic> respuesta;
    try {
      respuesta = await _apiClient.post(
        '/api/auth/token',
        data: {
          'username': usuario,
          'password': contrasena,
          'uuid_dispositivo': uuidDispositivo,
          'role_id': ?roleId,
        },
      );
    } on ApiExcepcionRed {
      return const LoginSinConexion();
    } on ApiExcepcionServidor catch (e) {
      return _resultadoDeError(e);
    } on ApiExcepcionDesconocida {
      return const LoginErrorDesconocido();
    }

    final cuerpo = respuesta.data as Map<String, dynamic>;
    await _tokenStore.guardarToken(cuerpo['token'] as String);
    final datosUsuario = cuerpo['usuario'] as Map<String, dynamic>;
    await _personaOperativaStore.guardarPersonaId(
      datosUsuario['persona_id'] as int?,
    );
    await _rolActivoStore.guardarRolActivo(
      RolActivo.fromJson(cuerpo['rol'] as Map<String, dynamic>),
    );
    return const LoginExitoso();
  }

  ResultadoLogin _resultadoDeError(ApiExcepcionServidor e) {
    switch (e.codigo) {
      case 401:
        return const LoginCredencialesInvalidas();
      case 409:
        return _resultadoDeRolAmbiguo(e.cuerpo);
      case 422:
        return LoginDatosInvalidos(_mensajeDe(e.cuerpo));
      default:
        return const LoginErrorDesconocido();
    }
  }

  /// El body del `409` no viene vacío nunca según el contrato (`roles` es
  /// obligatorio) — si viniera mal formado, cae a
  /// [LoginErrorDesconocido] en vez de asumir una lista vacía.
  ResultadoLogin _resultadoDeRolAmbiguo(Object? cuerpo) {
    if (cuerpo is Map) {
      final rolesJson = cuerpo['roles'];
      if (rolesJson is List && rolesJson.isNotEmpty) {
        try {
          final roles = rolesJson
              .map((rol) => RolActivo.fromJson(rol as Map<String, dynamic>))
              .toList();
          return LoginRolAmbiguo(roles);
        } on TypeError {
          return const LoginErrorDesconocido();
        }
      }
    }
    return const LoginErrorDesconocido();
  }

  String _mensajeDe(Object? cuerpo) {
    if (cuerpo is Map && cuerpo['message'] is String) {
      return cuerpo['message'] as String;
    }
    return 'Revisá los datos ingresados.';
  }
}
