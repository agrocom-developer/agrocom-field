// Etapa 1 de HU-20 (lado app): `VersionRepository` contra un `ApiClient`
// mockeado (mismo patrón que `test/nucleo/auth/login_service_test.dart`) —
// los cuatro casos de bloqueo por versión mínima: minima null, version_code
// igual, version_code por debajo, y error de red.

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/version/estado_version.dart';
import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:agrocom_field/nucleo/version/version_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

void main() {
  late _ApiClientFalso apiClient;
  late VersionRepository repositorio;

  setUp(() {
    apiClient = _ApiClientFalso();
    repositorio = VersionRepository(apiClient: apiClient);
  });

  Response<dynamic> respuesta(Object? minima, Object? vigente) =>
      Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/version'),
        statusCode: 200,
        data: {'minima': minima, 'vigente': vigente},
      );

  test(
    'minima null: VersionPermitida sin importar el version_code instalado',
    () async {
      when(
        () => apiClient.get('/api/version'),
      ).thenAnswer((_) async => respuesta(null, null));

      final estado = await repositorio.consultarEstado(1);

      expect(estado, const VersionPermitida());
    },
  );

  test('version_code instalado igual a la minima: VersionPermitida', () async {
    when(() => apiClient.get('/api/version')).thenAnswer(
      (_) async => respuesta({
        'version': '1.4.0',
        'version_code': 14000,
        'url_descarga': 'https://example.com/v1.4.0.apk',
      }, null),
    );

    final estado = await repositorio.consultarEstado(14000);

    expect(estado, const VersionPermitida());
  });

  test('version_code instalado por debajo de la minima: VersionBloqueada con '
      'la minima recibida', () async {
    when(() => apiClient.get('/api/version')).thenAnswer(
      (_) async => respuesta({
        'version': '1.4.0',
        'version_code': 14000,
        'url_descarga': 'https://example.com/v1.4.0.apk',
      }, null),
    );

    final estado = await repositorio.consultarEstado(13999);

    expect(
      estado,
      const VersionBloqueada(
        VersionApk(
          version: '1.4.0',
          versionCode: 14000,
          urlDescarga: 'https://example.com/v1.4.0.apk',
        ),
      ),
    );
  });

  test('error de red al consultar: VersionPermitida, no bloquea', () async {
    when(
      () => apiClient.get('/api/version'),
    ).thenThrow(const ApiExcepcionRed());

    final estado = await repositorio.consultarEstado(1);

    expect(estado, const VersionPermitida());
  });

  test(
    'error de servidor al consultar: VersionPermitida, no bloquea',
    () async {
      when(
        () => apiClient.get('/api/version'),
      ).thenThrow(const ApiExcepcionServidor(500, null));

      final estado = await repositorio.consultarEstado(1);

      expect(estado, const VersionPermitida());
    },
  );
}
