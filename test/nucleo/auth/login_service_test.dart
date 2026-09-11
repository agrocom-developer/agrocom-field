// Etapa 1 de HU-03 (+ etapa 1 de HU-69, ADR 0005): `LoginService` contra un
// `ApiClient` mockeado (mismo patrón que
// `test/nucleo/catalogo/catalogo_repository_test.dart`) — cubre los cuatro
// resultados de `POST /api/auth/token` (201/401/409/422) más el caso sin
// red, el `role_id` opcional del body y la persistencia del rol activo.

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/auth/dispositivo_store.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:agrocom_field/nucleo/auth/rol_activo.dart';
import 'package:agrocom_field/nucleo/auth/rol_activo_store.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

class _TokenStoreFalso extends Mock implements TokenStore {}

class _DispositivoStoreFalso extends Mock implements DispositivoStore {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _RolActivoStoreFalso extends Mock implements RolActivoStore {}

void main() {
  late _ApiClientFalso apiClient;
  late _TokenStoreFalso tokenStore;
  late _DispositivoStoreFalso dispositivoStore;
  late _PersonaOperativaStoreFalso personaOperativaStore;
  late _RolActivoStoreFalso rolActivoStore;
  late LoginService servicio;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(const RolActivo(id: 0, name: 'x'));
  });

  setUp(() {
    apiClient = _ApiClientFalso();
    tokenStore = _TokenStoreFalso();
    dispositivoStore = _DispositivoStoreFalso();
    personaOperativaStore = _PersonaOperativaStoreFalso();
    rolActivoStore = _RolActivoStoreFalso();
    when(
      () => dispositivoStore.obtenerUuidDispositivo(),
    ).thenAnswer((_) async => 'uuid-del-dispositivo');
    when(() => tokenStore.guardarToken(any())).thenAnswer((_) async {});
    when(
      () => personaOperativaStore.guardarPersonaId(any()),
    ).thenAnswer((_) async {});
    when(() => rolActivoStore.guardarRolActivo(any())).thenAnswer((_) async {});
    servicio = LoginService(
      apiClient: apiClient,
      tokenStore: tokenStore,
      dispositivoStore: dispositivoStore,
      personaOperativaStore: personaOperativaStore,
      rolActivoStore: rolActivoStore,
    );
  });

  Response<dynamic> respuesta(int codigo, Object? data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/auth/token'),
    statusCode: codigo,
    data: data,
  );

  test('201: guarda el token, el persona_id y el rol activo, devuelve '
      'LoginExitoso', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => respuesta(201, {
        'token': '12|aB3cD4',
        'token_type': 'Bearer',
        'usuario': {
          'id': 7,
          'name': 'Camila Rojas',
          'username': 'camila.rojas',
          'persona_id': 3,
        },
        'rol': {'id': 1, 'name': 'piloto', 'description': 'Piloto de dron'},
      }),
    );

    final resultado = await servicio.login(
      usuario: 'camila.rojas',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginExitoso>());
    verify(() => tokenStore.guardarToken('12|aB3cD4')).called(1);
    verify(() => personaOperativaStore.guardarPersonaId(3)).called(1);
    verify(
      () => rolActivoStore.guardarRolActivo(
        const RolActivo(id: 1, name: 'piloto', description: 'Piloto de dron'),
      ),
    ).called(1);
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

  test('201 con persona_id nulo: guarda null, no falla ni lo omite', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => respuesta(201, {
        'token': '12|aB3cD4',
        'token_type': 'Bearer',
        'usuario': {
          'id': 7,
          'name': 'Sin Persona',
          'username': 'sin.persona',
          'persona_id': null,
        },
        'rol': {'id': 2, 'name': 'auxiliar', 'description': null},
      }),
    );

    final resultado = await servicio.login(
      usuario: 'sin.persona',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginExitoso>());
    verify(() => personaOperativaStore.guardarPersonaId(null)).called(1);
  });

  test('con roleId: lo manda como role_id en el body', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => respuesta(201, {
        'token': '12|aB3cD4',
        'token_type': 'Bearer',
        'usuario': {
          'id': 9,
          'name': 'Miguelito Justiniano',
          'username': 'miguelito.justiniano',
          'persona_id': null,
        },
        'rol': {'id': 1, 'name': 'piloto', 'description': null},
      }),
    );

    final resultado = await servicio.login(
      usuario: 'miguelito.justiniano',
      contrasena: 'password',
      roleId: 1,
    );

    expect(resultado, isA<LoginExitoso>());
    verify(
      () => apiClient.post(
        '/api/auth/token',
        data: {
          'username': 'miguelito.justiniano',
          'password': 'password',
          'uuid_dispositivo': 'uuid-del-dispositivo',
          'role_id': 1,
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

  test('409: rol ambiguo, expone los roles del cuerpo, no guarda ningún '
      'token a medias', () async {
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenThrow(
      const ApiExcepcionServidor(409, {
        'message': 'Elegí un rol.',
        'roles': [
          {'id': 1, 'name': 'piloto', 'description': null},
          {'id': 2, 'name': 'auxiliar', 'description': 'Auxiliar de campo'},
        ],
      }),
    );

    final resultado = await servicio.login(
      usuario: 'miguelito.justiniano',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginRolAmbiguo>());
    expect((resultado as LoginRolAmbiguo).roles, [
      const RolActivo(id: 1, name: 'piloto'),
      const RolActivo(
        id: 2,
        name: 'auxiliar',
        description: 'Auxiliar de campo',
      ),
    ]);
    verifyNever(() => tokenStore.guardarToken(any()));
  });

  test('409 sin roles (o con roles vacío/mal formado): cae a '
      'LoginErrorDesconocido, nunca asume una lista vacía', () async {
    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenThrow(const ApiExcepcionServidor(409, {'message': 'Elegí un rol.'}));

    final resultado = await servicio.login(
      usuario: 'miguelito.justiniano',
      contrasena: 'password',
    );

    expect(resultado, isA<LoginErrorDesconocido>());
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
