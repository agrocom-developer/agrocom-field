// Acceso del cliente según el contrato de cuenta: `app` en el ingreso,
// `429`, `403 tipo_de_cuenta_incorrecto`, `409 cuenta_ya_registrada`, sesión
// restringida por eliminación, cuenta regresiva del ingreso y renovación de la
// sesión al desbloquear con la biometría.

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/data/acceso_red.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/acceso/presentation/arranque_cubit.dart';
import 'package:agrocom_field/cliente/acceso/presentation/login_cliente_cubit.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/auth/biometria.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../red/dobles_red.dart';

class _Onboarding implements OnboardingStore {
  @override
  Future<bool> visto() async => true;

  @override
  Future<void> marcar() async {}
}

final _usuarioJson = {
  'id': 7,
  'name': 'Rosa Condori',
  'username': 'rosa.c',
  'persona_id': null,
};

final _token = {
  'token': 'tok-1',
  'token_type': 'Bearer',
  'usuario': _usuarioJson,
  'rol': {'id': 6, 'name': 'cliente', 'description': 'Cliente'},
  'dispositivo': {},
};

void main() {
  group('AccesoRed según el contrato de cuenta', () {
    late EntornoRed red;
    late AccesoRed acceso;

    setUp(() {
      red = EntornoRed(token: null);
      acceso = AccesoRed(
        api: red.api,
        tokenStore: red.tokens,
        dispositivoStore: DispositivoFijo(),
        onboarding: _Onboarding(),
      );
      red.servidor.responder('DELETE', '/api/auth/token', codigo: 204);
    });

    test('el ingreso declara la app cliente y acepta teléfono', () async {
      red.servidor
        ..responder('POST', '/api/auth/token', codigo: 201, cuerpo: _token)
        ..responder(
          'GET',
          '/api/auth/sesion',
          cuerpo: {'usuario': _usuarioJson, 'rol': _token['rol']},
        )
        ..responder(
          'GET',
          '/api/clientes/mi',
          cuerpo: {
            'cliente': {'id': 1, 'tipo': 'persona', 'telefono': '+59170012345'},
          },
        );
      await acceso.iniciarSesion(usuario: ' 70012345 ', contrasena: 'abcd');
      final cuerpo =
          red.servidor.de('POST', '/api/auth/token').single.cuerpo! as Map;
      expect(cuerpo['app'], 'cliente');
      expect(cuerpo['username'], '70012345');
    });

    test('429 se distingue de una contraseña errada', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 429,
        cuerpo: {},
      );
      await expectLater(
        acceso.iniciarSesion(usuario: 'rosa', contrasena: 'x'),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFalloAcceso.demasiadosIntentos,
          ),
        ),
      );
    });

    test('403 tipo_de_cuenta_incorrecto explica a qué app ir', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 403,
        cuerpo: {
          'message':
              'Esta cuenta es de proveedor: ingresa en la app Agrocom '
              'Piloto.',
          'codigo': 'tipo_de_cuenta_incorrecto',
          'tipo_cuenta': 'proveedor',
        },
      );
      await expectLater(
        acceso.iniciarSesion(usuario: 'carlos', contrasena: 'abcd'),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.porCampo[CampoAcceso.usuario],
            'mensaje',
            contains('app Agrocom Piloto'),
          ),
        ),
      );
      expect(red.tokens.token, isNull);
    });

    test('409 cuenta_ya_registrada no crea cuenta ni inicia sesión', () async {
      red.servidor.responder(
        'POST',
        '/api/clientes/registro',
        codigo: 409,
        cuerpo: {
          'message': 'Ya tienes una cuenta.',
          'codigo': 'cuenta_ya_registrada',
          'tipo_cuenta': 'cliente',
        },
      );
      await expectLater(
        acceso.registrar(
          const DatosRegistroCliente(
            nombre: 'Rosa Condori',
            telefono: '70012345',
            usuario: 'rosa.c',
            contrasena: 'abcd',
          ),
        ),
        throwsA(
          isA<AccesoExcepcion>()
              .having(
                (e) => e.motivo,
                'motivo',
                MotivoFalloAcceso.cuentaYaRegistrada,
              )
              .having((e) => e.tipoCuenta, 'tipoCuenta', 'cliente'),
        ),
      );
      expect(red.servidor.de('POST', '/api/auth/token'), isEmpty);
    });

    test('una cuenta en eliminación entra con la sesión restringida', () async {
      red.servidor
        ..responder('POST', '/api/auth/token', codigo: 201, cuerpo: _token)
        ..responder(
          'GET',
          '/api/auth/sesion',
          codigo: 403,
          cuerpo: {'message': 'x', 'codigo': 'cuenta_en_eliminacion'},
        );
      final s = await acceso.iniciarSesion(
        usuario: 'rosa.c',
        contrasena: 'abcd',
      );
      expect(s.enEliminacion, isTrue);
      expect(s.nombre, 'Rosa Condori');
      // El token se conserva: con él se ve el estado y se cancela.
      expect(red.tokens.token, 'tok-1');
    });

    test('al abrir con la sesión restringida no descarta el token', () async {
      red.tokens.token = 'tok-1';
      red.servidor.responder(
        'GET',
        '/api/auth/sesion',
        codigo: 403,
        cuerpo: {'message': 'x', 'codigo': 'cuenta_en_eliminacion'},
      );
      final s = await acceso.sesionActual();
      expect(s?.enEliminacion, isTrue);
      expect(red.tokens.token, 'tok-1');
    });
  });

  group('LoginClienteCubit', () {
    test('tras un 429 espera la cuenta regresiva y vuelve a permitir', () async {
      final acceso = _Falla(
        const AccesoExcepcion(
          MotivoFalloAcceso.demasiadosIntentos,
          esperaSegundos: 3,
        ),
      );
      final c = LoginClienteCubit(
        acceso,
        paso: const Duration(milliseconds: 4),
      );
      await c.enviar(usuario: 'rosa', contrasena: 'x');
      expect(c.state.enEspera, isTrue);
      expect(c.state.esperaSegundos, inInclusiveRange(1, 3));
      expect(
        c.state.mensajeFallo(AppLocalizationsEs()),
        contains('Podrás volver a intentarlo en'),
      );
      // Mientras espera no se vuelve a pedir ni se borra el aviso al escribir.
      await c.enviar(usuario: 'rosa', contrasena: 'x');
      c.limpiarFallo();
      expect(acceso.intentos, 1);
      expect(c.state.enEspera, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.state.enEspera, isFalse);
      expect(c.state.fallo, isNull);
      await c.close();
    });

    test('un 429 sin Retry-After usa la espera por defecto', () async {
      final c = LoginClienteCubit(
        _Falla(const AccesoExcepcion(MotivoFalloAcceso.demasiadosIntentos)),
        esperaPorDefecto: const Duration(seconds: 45),
        paso: const Duration(seconds: 10),
      );
      await c.enviar(usuario: 'rosa', contrasena: 'x');
      expect(c.state.esperaSegundos, 45);
      await c.close();
    });
  });

  group('ArranqueCubit', () {
    late BiometriaFalsa biometria;
    late BloqueoBiometricoStoreEnMemoria store;
    late BloqueoBiometrico bloqueo;

    setUp(() {
      biometria = BiometriaFalsa();
      store = BloqueoBiometricoStoreEnMemoria();
      bloqueo = BloqueoBiometrico(biometria, store);
    });

    AccesoDemo demo() => AccesoDemo(
      AlmacenDemoCliente(),
      latencia: Duration.zero,
      onboardingVisto: true,
      sesionIniciada: true,
    );

    test('al desbloquear con la biometría renueva la sesión', () async {
      await store.guardar(true);
      var renovaciones = 0;
      final c = ArranqueCubit(
        demo(),
        bloqueo: bloqueo,
        l10n: AppLocalizationsEs(),
        renovarSesion: () async {
          renovaciones++;
          return true;
        },
      );
      await c.resolver();
      expect(renovaciones, 1);
      expect(c.state.etapa, EtapaArranque.dentro);
      await c.close();
    });

    test('cancelar la biometría no renueva nada', () async {
      await store.guardar(true);
      biometria.resultado = ResultadoBiometria.cancelado;
      var renovaciones = 0;
      final c = ArranqueCubit(
        demo(),
        bloqueo: bloqueo,
        l10n: AppLocalizationsEs(),
        renovarSesion: () async {
          renovaciones++;
          return true;
        },
      );
      await c.resolver();
      expect(renovaciones, 0);
      expect(c.state.etapa, EtapaArranque.bloqueada);
      await c.close();
    });

    test('una falla al renovar no impide entrar', () async {
      await store.guardar(true);
      final c = ArranqueCubit(
        demo(),
        bloqueo: bloqueo,
        l10n: AppLocalizationsEs(),
        renovarSesion: () async => throw StateError('sin red'),
      );
      await c.resolver();
      expect(c.state.etapa, EtapaArranque.dentro);
      await c.close();
    });

    test('una sesión en eliminación va a su pantalla, no a la app', () async {
      final c = ArranqueCubit(demo());
      c.sesionIniciada(
        const SesionCliente(
          nombre: 'Rosa',
          usuario: 'rosa.c',
          enEliminacion: true,
        ),
      );
      expect(c.state.etapa, EtapaArranque.enEliminacion);
      await c.close();
    });
  });
}

class _Falla extends AccesoDemo {
  _Falla(this.falla) : super(AlmacenDemoCliente(), latencia: Duration.zero);

  final AccesoExcepcion falla;
  int intentos = 0;

  @override
  Future<SesionCliente> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    intentos++;
    throw falla;
  }
}
