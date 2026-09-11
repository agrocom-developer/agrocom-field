import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import 'dispositivo_store.dart';
import 'resultado_login.dart';
import 'token_store.dart';

/// Caso de uso de HU-03: intercambia usuario/contraseña por el token de
/// dispositivo (`POST /api/auth/token`, operationId
/// `emitirTokenDispositivo`) y lo persiste con [TokenStore.guardarToken].
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
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _dispositivoStore = dispositivoStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final DispositivoStore _dispositivoStore;

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
