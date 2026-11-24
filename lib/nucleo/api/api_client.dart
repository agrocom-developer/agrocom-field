// Infraestructura pura: NUNCA se llama desde un bloc ni desde presentation/.
// Lo usan los repositorios de nucleo/sync (y de nucleo/catalogo) y las
// implementaciones de red del flavor cliente (`cliente/*/data/`, online-first).
// En piloto y auxiliar, si un bloc necesita datos, los pide al repositorio
// local (drift), nunca acá directo — invariante 1 de CLAUDE.md.
//
// Ver docs/decisiones/0001-cliente-api-manual-con-dio.md de este repo.

import 'package:dio/dio.dart';

import 'api_excepcion.dart';
import 'interceptores/auth_interceptor.dart';
import '../auth/token_store.dart';

class ApiClient {
  /// [dio] permite a las pruebas inyectar un adaptador falso.
  ApiClient({required String baseUrl, required TokenStore tokenStore, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(AuthInterceptor(tokenStore));
  }

  final Dio _dio;

  /// Se invoca cuando un request autenticado recibe `401` (token vencido o
  /// revocado). Quien lo asigna decide qué hacer: el flavor cliente borra el
  /// token y vuelve al acceso. No se invoca para `POST /api/auth/token`.
  void Function()? alSesionExpirada;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _envolver(() => _dio.get(path, queryParameters: query));

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _envolver(() => _dio.post(path, data: data));

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _envolver(() => _dio.put(path, data: data));

  Future<Response<dynamic>> delete(String path) =>
      _envolver(() => _dio.delete(path));

  Future<Response<dynamic>> _envolver(
    Future<Response<dynamic>> Function() llamada,
  ) async {
    try {
      return await llamada();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          e.requestOptions.path != '/api/auth/token') {
        alSesionExpirada?.call();
      }
      throw mapearExcepcionDio(e);
    }
  }
}
