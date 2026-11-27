// `Retry-After` de un `429` llega a la excepción del servidor: las pantallas de
// código y de ingreso muestran la cuenta regresiva con esos segundos.

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adaptador implements HttpClientAdapter {
  _Adaptador(this.encabezados);

  final Map<String, List<String>> encabezados;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"message":"Demasiados intentos"}',
    429,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...encabezados,
    },
  );

  @override
  void close({bool force = false}) {}
}

class _Token implements TokenStore {
  @override
  Future<String?> leerToken() async => null;

  @override
  Future<void> guardarToken(String token) async {}

  @override
  Future<void> borrarToken() async {}
}

Future<ApiExcepcionServidor> _pedir(
  Map<String, List<String>> encabezados,
) async {
  final api = ApiClient(
    baseUrl: 'http://api.prueba',
    tokenStore: _Token(),
    dio: Dio(BaseOptions(baseUrl: 'http://api.prueba'))
      ..httpClientAdapter = _Adaptador(encabezados),
  );
  try {
    await api.post('/api/auth/recuperar');
  } on ApiExcepcionServidor catch (e) {
    return e;
  }
  fail('Debió fallar con 429');
}

void main() {
  test('Retry-After en segundos queda en reintentarEn', () async {
    final e = await _pedir({
      'retry-after': ['45'],
    });
    expect(e.codigo, 429);
    expect(e.reintentarEn, const Duration(seconds: 45));
  });

  test('sin el encabezado, reintentarEn es null', () async {
    final e = await _pedir({});
    expect(e.reintentarEn, isNull);
  });

  test('una fecha HTTP o un valor ilegible se ignoran', () async {
    final fecha = await _pedir({
      'retry-after': ['Wed, 21 Oct 2026 07:28:00 GMT'],
    });
    expect(fecha.reintentarEn, isNull);
    final cero = await _pedir({
      'retry-after': ['0'],
    });
    expect(cero.reintentarEn, isNull);
  });
}
