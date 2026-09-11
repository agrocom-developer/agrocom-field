// Etapa 1 de HU-03: `LoginService` contra un `ApiClient` mockeado (mismo
// patrón que `test/nucleo/catalogo/catalogo_repository_test.dart`) — cubre
// los cuatro resultados de `POST /api/auth/token` (201/401/409/422) más el
// caso sin red.

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/auth/dispositivo_store.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

class _TokenStoreFalso extends Mock implements TokenStore {}

class _DispositivoStoreFalso extends Mock implements DispositivoStore {}

void main() {
  late _ApiClientFalso apiClient;
  late _TokenStoreFalso tokenStore;
  late _DispositivoStoreFalso dispositivoStore;
  late LoginService servicio;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    apiClient = _ApiClientFalso();
    tokenStore = _TokenStoreFalso();
    dispositivoStore = _DispositivoStoreFalso();
    when(
      () => dispositivoStore.obtenerUuidDispositivo(),
    ).thenAnswer((_) async => 'uuid-del-dispositivo');
    when(() => tokenStore.guardarToken(any())).thenAnswer((_) async {});
    servicio = LoginService(
      apiClient: apiClient,
      tokenStore: tokenStore,
      dispositivoStore: dispositivoStore,
    );
  });

  Response<dynamic> respuesta(int codigo, Object? data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/auth/token'),
    statusCode: codigo,
    data: data,
  );

  test('201: guarda el token y devuelve LoginExitoso', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async =>
          respuesta(201, {'token': '12|aB3cD4', 'token_type': 'Bearer'}),
    );

    final resultado = await servicio.login(
      usuario: 'camila.rojas',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginExitoso>());
    verify(() => tokenStore.guardarToken('12|aB3cD4')).called(1);
    verify(
      () => apiClient.post(
        '/api/auth/token',
        data: {
          'username': 'camila.rojas',
          'password': 'password',
          'uuid_dispositivo': 'uuid-del-dispositivo',
        },
      ),
    ).called(1);
  });

  test('401: credenciales inválidas, no guarda ningún token', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenThrow(
      const ApiExcepcionServidor(401, {'message': 'Unauthenticated.'}),
    );

    final resultado = await servicio.login(
      usuario: 'camila.rojas',
      contrasena: 'mala',
    );

    expect(resultado, isA<LoginCredencialesInvalidas>());
    verifyNever(() => tokenStore.guardarToken(any()));
  });

  test('409: rol ambiguo, no guarda ningún token a medias', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenThrow(
      const ApiExcepcionServidor(409, {
        'message': 'Elegí un rol.',
        'roles': [
          {'id': 1, 'name': 'piloto', 'description': null},
          {'id': 2, 'name': 'auxiliar', 'description': null},
        ],
      }),
    );

    final resultado = await servicio.login(
      usuario: 'miguelito.justiniano',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginRolAmbiguo>());
    verifyNever(() => tokenStore.guardarToken(any()));
  });

  test('422: payload inválido, expone el mensaje del servidor', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenThrow(
      const ApiExcepcionServidor(422, {
        'message': 'El campo password es obligatorio.',
        'errors': {
          'password': ['El campo password es obligatorio.'],
        },
      }),
    );

    final resultado = await servicio.login(
      usuario: 'camila.rojas',
      contrasena: '',
    );

    expect(
      resultado,
      const LoginDatosInvalidos('El campo password es obligatorio.'),
    );
    verifyNever(() => tokenStore.guardarToken(any()));
  });

  test('422 sin cuerpo parseable: cae a un mensaje por defecto', () async {
    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenThrow(const ApiExcepcionServidor(422, null));

    final resultado = await servicio.login(usuario: 'x', contrasena: 'y');

    expect(resultado, isA<LoginDatosInvalidos>());
    expect(
      (resultado as LoginDatosInvalidos).mensaje,
      'Revisá los datos ingresados.',
    );
  });

  test('sin red: devuelve LoginSinConexion, no guarda ningún token', () async {
    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenThrow(const ApiExcepcionRed());

    final resultado = await servicio.login(
      usuario: 'camila.rojas',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginSinConexion>());
    verifyNever(() => tokenStore.guardarToken(any()));
  });

  test(
    'código de servidor inesperado: devuelve LoginErrorDesconocido',
    () async {
      when(
        () => apiClient.post(any(), data: any(named: 'data')),
      ).thenThrow(const ApiExcepcionServidor(500, null));

      final resultado = await servicio.login(
        usuario: 'camila.rojas',
        contrasena: 'password',
      );

      expect(resultado, isA<LoginErrorDesconocido>());
    },
  );
}
