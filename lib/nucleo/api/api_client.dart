// Infraestructura pura: NUNCA se llama desde un bloc ni desde presentation/.
// Solo los repositorios de nucleo/sync (y más adelante nucleo/catalogo) usan
// este cliente. Si un bloc necesita datos, los pide al repositorio local
// (drift), nunca acá directo — invariante 1 de CLAUDE.md.
//
// Ver docs/decisiones/0001-cliente-api-manual-con-dio.md de este repo.

import 'package:dio/dio.dart';

import 'api_excepcion.dart';
import 'interceptores/auth_interceptor.dart';
import '../auth/token_store.dart';

class ApiClient {
  ApiClient({required String baseUrl, required TokenStore tokenStore})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    _dio.interceptors.add(AuthInterceptor(tokenStore));
  }

  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _envolver(() => _dio.get(path, queryParameters: query));

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _envolver(() => _dio.post(path, data: data));

  Future<Response<dynamic>> _envolver(
    Future<Response<dynamic>> Function() llamada,
  ) async {
    try {
      return await llamada();
    } on DioException catch (e) {
      throw mapearExcepcionDio(e);
    }
  }
}
