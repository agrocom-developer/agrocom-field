// `CuentaSeguridadRed` contra un `ApiClient` falso: rutas, cuerpos, el
// contrato de errores de cuenta (422/429/503/409/403) y la renovación de la
// sesión.

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/data/cuenta_seguridad_red.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiFalso extends Mock implements ApiClient {}

class _TokenFalso extends Mock implements TokenStore {}

Response<dynamic> _ok(Object? data, [int codigo = 200]) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/x'),
  statusCode: codigo,
  data: data,
);

void main() {
  late _ApiFalso api;
  late _TokenFalso tokens;
  late CuentaSeguridadRed repo;
  final ahora = DateTime.utc(2026, 11, 27, 12);

  setUp(() {
    api = _ApiFalso();
    tokens = _TokenFalso();
    when(() => tokens.guardarToken(any())).thenAnswer((_) async {});
    repo = CuentaSeguridadRed(api: api, tokenStore: tokens, ahora: () => ahora);
  });

  group('recuperación del acceso', () {
    test('envía identificador, app y canal', () async {
      when(
        () => api.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _ok({'message': 'ok'}, 202));
      await repo.pedirRecuperacion(
        identificador: '  70012345 ',
        app: AppCuenta.proveedor,
        canal: CanalCodigo.sms,
      );
      verify(
        () => api.post(
          '/api/auth/recuperar',
          data: {
            'identificador': '70012345',
            'app': 'proveedor',
            'canal': 'sms',
          },
        ),
      ).called(1);
    });

    test('confirmar devuelve el usuario de la cuenta', () async {
      when(
        () => api.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _ok({'message': 'ok', 'username': 'rosa.c'}));
      final usuario = await repo.confirmarRecuperacion(
        identificador: 'rosa',
        app: AppCuenta.cliente,
        codigo: ' 482913 ',
        contrasenaNueva: 'abcd',
      );
      expect(usuario, 'rosa.c');
      verify(
        () => api.post(
          '/api/auth/recuperar/confirmar',
          data: {
            'identificador': 'rosa',
            'app': 'cliente',
            'codigo': '482913',
            'password_nueva': 'abcd',
          },
        ),
      ).called(1);
    });

    test('503 canal_no_disponible es un fallo de canal, no de la persona', () {
      when(() => api.post(any(), data: any(named: 'data'))).thenThrow(
        const ApiExcepcionServidor(503, {
          'message': 'x',
          'codigo': 'canal_no_disponible',
          'canal': 'whatsapp',
        }),
      );
      expect(
        repo.pedirRecuperacion(
          identificador: 'a',
          app: AppCuenta.cliente,
          canal: CanalCodigo.whatsapp,
        ),
        throwsA(
          isA<CuentaCanalNoDisponible>().having(
            (f) => f.canal,
            'canal',
            CanalCodigo.whatsapp,
          ),
        ),
      );
    });

    test('429 trae la espera de Retry-After', () {
      when(() => api.post(any(), data: any(named: 'data'))).thenThrow(
        const ApiExcepcionServidor(
          429,
          null,
          reintentarEn: Duration(seconds: 90),
        ),
      );
      expect(
        repo.pedirRecuperacion(
          identificador: 'a',
          app: AppCuenta.cliente,
          canal: CanalCodigo.correo,
        ),
        throwsA(
          isA<CuentaLimiteExcedido>().having(
            (f) => f.espera,
            'espera',
            const Duration(seconds: 90),
          ),
        ),
      );
    });

    test('422 codigo_invalido y 422 con errores por campo se distinguen', () {
      expect(
        CuentaSeguridadRed.traducirFalla(
          const ApiExcepcionServidor(422, {'codigo': 'codigo_invalido'}),
        ),
        isA<CuentaCodigoInvalido>(),
      );
      final datos = CuentaSeguridadRed.traducirFalla(
        const ApiExcepcionServidor(422, {
          'message': 'Datos inválidos',
          'errors': {
            'password_nueva': ['Mínimo 4 caracteres'],
          },
        }),
      );
      expect(datos, isA<CuentaDatosInvalidos>());
      expect(
        (datos as CuentaDatosInvalidos).porCampo['password_nueva'],
        'Mínimo 4 caracteres',
      );
    });

    test('sin red lanza CuentaSinConexion', () {
      when(
        () => api.post(any(), data: any(named: 'data')),
      ).thenThrow(const ApiExcepcionRed());
      expect(
        repo.pedirCodigoContrasena(CanalCodigo.correo),
        throwsA(isA<CuentaSinConexion>()),
      );
    });
  });

  group('con sesión', () {
    test(
      'pedir código de contraseña devuelve el destino enmascarado',
      () async {
        when(() => api.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => _ok({'message': 'ok', 'destino': '+591 ••••• 45'}, 202),
        );
        final r = await repo.pedirCodigoContrasena(CanalCodigo.whatsapp);
        expect(r.destino, '+591 ••••• 45');
      },
    );

    test('cambiar contraseña usa PUT con el código y la nueva', () async {
      when(
        () => api.put(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _ok({'message': 'ok'}));
      await repo.cambiarContrasena(codigo: '123456', contrasenaNueva: 'xyz1');
      verify(
        () => api.put(
          '/api/cuenta/contrasena',
          data: {'codigo': '123456', 'password_nueva': 'xyz1'},
        ),
      ).called(1);
    });

    test('409 telefono_ya_verificado', () {
      when(() => api.post(any(), data: any(named: 'data'))).thenThrow(
        const ApiExcepcionServidor(409, {'codigo': 'telefono_ya_verificado'}),
      );
      expect(
        repo.pedirCodigoTelefono(CanalCodigo.sms),
        throwsA(isA<CuentaTelefonoYaVerificado>()),
      );
    });

    test('perfil lee telefono_verificado y expira_en', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => _ok({
          'usuario': {'telefono_verificado': true, 'foto_url': '/f'},
          'dispositivo': {'expira_en': '2026-12-01T00:00:00Z'},
        }),
      );
      final p = await repo.perfil();
      expect(p.telefonoVerificado, isTrue);
      expect(p.fotoUrl, '/f');
      expect(p.expiraEn, DateTime.utc(2026, 12));
    });
  });

  group('renovar la sesión', () {
    void sesionQueExpira(String expira) =>
        when(() => api.get(any())).thenAnswer(
          (_) async => _ok({
            'usuario': {'telefono_verificado': true},
            'dispositivo': {'expira_en': expira},
          }),
        );

    test('con pocos días de vida pide un token nuevo y lo guarda', () async {
      sesionQueExpira('2026-11-30T00:00:00Z');
      when(() => api.post('/api/auth/renovar')).thenAnswer(
        (_) async => _ok({'token': '99|nuevo', 'token_type': 'Bearer'}, 201),
      );
      expect(await repo.renovarSiCorresponde(), isTrue);
      verify(() => tokens.guardarToken('99|nuevo')).called(1);
    });

    test('con mucha vida por delante no hace nada', () async {
      sesionQueExpira('2027-01-15T00:00:00Z');
      expect(await repo.renovarSiCorresponde(), isFalse);
      verifyNever(() => api.post('/api/auth/renovar'));
      verifyNever(() => tokens.guardarToken(any()));
    });

    test('un token que no caduca no se renueva', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => _ok({
          'usuario': {'telefono_verificado': true},
          'dispositivo': {'expira_en': null},
        }),
      );
      expect(await repo.renovarSiCorresponde(), isFalse);
    });

    test('sin red conserva el token guardado y no lanza', () async {
      sesionQueExpira('2026-11-30T00:00:00Z');
      when(
        () => api.post('/api/auth/renovar'),
      ).thenThrow(const ApiExcepcionRed());
      expect(await repo.renovarSiCorresponde(), isFalse);
      verifyNever(() => tokens.guardarToken(any()));
    });

    test('401 al renovar no lanza (el cliente HTTP ya volvió al ingreso)', () {
      sesionQueExpira('2026-11-30T00:00:00Z');
      when(
        () => api.post('/api/auth/renovar'),
      ).thenThrow(const ApiExcepcionServidor(401, null));
      expect(repo.renovarSiCorresponde(), completion(isFalse));
    });
  });

  group('eliminar la cuenta', () {
    test('consulta: estado e impedimentos', () async {
      when(() => api.get('/api/cuenta/eliminacion')).thenAnswer(
        (_) async => _ok({
          'eliminacion': null,
          'impedimentos': [
            'servicio_en_curso',
            'desconocido',
            'reclamo_abierto',
          ],
        }),
      );
      final c = await repo.consultarEliminacion();
      expect(c.eliminacion, isNull);
      expect(c.bloqueada, isTrue);
      expect(c.impedimentos, [
        ImpedimentoEliminacion.servicioEnCurso,
        ImpedimentoEliminacion.reclamoAbierto,
      ]);
    });

    test(
      'con contraseña envía solo password; con código, solo codigo',
      () async {
        when(() => api.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => _ok({
            'eliminacion': {
              'estado': 'solicitada',
              'solicitada_en': '2026-11-27T12:00:00Z',
              'ejecutar_desde': '2026-12-04T12:00:00Z',
              'cancelada_en': null,
              'motivo_posposicion': null,
            },
          }, 202),
        );
        final e = await repo.eliminarCuenta(contrasena: 'abcd');
        expect(e.estado, EstadoEliminacion.solicitada);
        expect(e.ejecutarDesde, DateTime.utc(2026, 12, 4, 12));
        await repo.eliminarCuenta(codigo: '123456');
        verify(
          () => api.post('/api/cuenta/eliminacion', data: {'password': 'abcd'}),
        ).called(1);
        verify(
          () => api.post('/api/cuenta/eliminacion', data: {'codigo': '123456'}),
        ).called(1);
      },
    );

    test('409 eliminacion_bloqueada trae los motivos', () {
      when(() => api.post(any(), data: any(named: 'data'))).thenThrow(
        const ApiExcepcionServidor(409, {
          'codigo': 'eliminacion_bloqueada',
          'motivos': ['pilotos_vinculados'],
        }),
      );
      expect(
        repo.eliminarCuenta(contrasena: 'x'),
        throwsA(
          isA<CuentaEliminacionBloqueada>().having(
            (f) => f.motivos,
            'motivos',
            [ImpedimentoEliminacion.pilotosVinculados],
          ),
        ),
      );
    });

    test('422 contrasena_incorrecta', () {
      when(() => api.post(any(), data: any(named: 'data'))).thenThrow(
        const ApiExcepcionServidor(422, {'codigo': 'contrasena_incorrecta'}),
      );
      expect(
        repo.eliminarCuenta(contrasena: 'x'),
        throwsA(isA<CuentaContrasenaIncorrecta>()),
      );
    });

    test('403 cuenta_en_eliminacion', () {
      expect(
        CuentaSeguridadRed.traducirFalla(
          const ApiExcepcionServidor(403, {'codigo': 'cuenta_en_eliminacion'}),
        ),
        isA<CuentaEnEliminacion>(),
      );
    });

    test('conservar la cuenta llama a cancelar', () async {
      when(() => api.post('/api/cuenta/eliminacion/cancelar')).thenAnswer(
        (_) async => _ok({
          'eliminacion': {
            'estado': 'cancelada',
            'solicitada_en': '2026-11-27T12:00:00Z',
            'ejecutar_desde': '2026-12-04T12:00:00Z',
          },
        }),
      );
      final e = await repo.conservarCuenta();
      expect(e.estado, EstadoEliminacion.cancelada);
      expect(e.vigente, isFalse);
    });
  });

  group('dominio', () {
    test('ReglasContrasena: mínimo 4, máximo 100, sin composición', () {
      expect(ReglasContrasena.validarNueva(''), isNotNull);
      expect(ReglasContrasena.validarNueva('abc'), isNotNull);
      expect(ReglasContrasena.validarNueva('abcd'), isNull);
      expect(ReglasContrasena.validarNueva('1234'), isNull);
      expect(ReglasContrasena.validarNueva('a' * 100), isNull);
      expect(ReglasContrasena.validarNueva('a' * 101), isNotNull);
      expect(ReglasContrasena.validarIngreso(''), isNotNull);
      expect(ReglasContrasena.validarIngreso('x'), isNull);
    });

    test('días restantes de la gracia', () {
      final e = EliminacionCuenta(
        estado: EstadoEliminacion.solicitada,
        solicitadaEn: DateTime.utc(2026, 11, 27),
        ejecutarDesde: DateTime.utc(2026, 12, 4),
      );
      expect(e.diasRestantes(DateTime.utc(2026, 11, 27)), 7);
      expect(e.diasRestantes(DateTime.utc(2026, 12, 3, 12)), 1);
      expect(e.diasRestantes(DateTime.utc(2026, 12, 9)), 0);
    });
  });
}
