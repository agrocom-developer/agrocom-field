import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import 'dispositivo_store.dart';
import 'persona_operativa_store.dart';
import 'resultado_login.dart';
import 'token_store.dart';

/// Caso de uso de HU-03: intercambia usuario/contraseña por el token de
/// dispositivo (`POST /api/auth/token`, operationId
/// `emitirTokenDispositivo`) y lo persiste con [TokenStore.guardarToken].
/// También persiste `usuario.persona_id` (HU-05: lo necesita
/// `AperturaSesion.piloto_id`) con [PersonaOperativaStore] — nullable, así
/// que un usuario sin persona operativa enlazada queda con `null` guardado,
/// nunca con un valor de un login anterior.
///
/// No maneja el selector de rol del `409` (HU-69, fuera de alcance de esta
/// tarea) — lo expone como [LoginRolAmbiguo], un resultado distinguible
/// para que la pantalla muestre un mensaje, sin guardar ningún token a
/// medias.
class LoginService {
  LoginService({
    required ApiClient apiClient,
    required TokenStore tokenStore,
    required DispositivoStore dispositivoStore,
    required PersonaOperativaStore personaOperativaStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _dispositivoStore = dispositivoStore,
       _personaOperativaStore = personaOperativaStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final DispositivoStore _dispositivoStore;
  final PersonaOperativaStore _personaOperativaStore;

  Future<ResultadoLogin> login({
    required String usuario,
    required String contrasena,
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
    return const LoginExitoso();
  }

  ResultadoLogin _resultadoDeError(ApiExcepcionServidor e) {
    switch (e.codigo) {
      case 401:
        return const LoginCredencialesInvalidas();
      case 409:
        return const LoginRolAmbiguo();
      case 422:
        return LoginDatosInvalidos(_mensajeDe(e.cuerpo));
      default:
        return const LoginErrorDesconocido();
    }
  }

  String _mensajeDe(Object? cuerpo) {
    if (cuerpo is Map && cuerpo['message'] is String) {
      return cuerpo['message'] as String;
    }
    return 'Revisá los datos ingresados.';
  }
}
