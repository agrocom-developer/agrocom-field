import 'package:agrocom_field/nucleo/cuenta/data/contrasena_demo.dart';
import 'package:agrocom_field/nucleo/cuenta/domain/contrasena_repositorio.dart';
import 'package:agrocom_field/nucleo/cuenta/presentation/cambiar_contrasena_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:flutter_test/flutter_test.dart';

class _Falso implements ContrasenaRepositorio {
  _Falso({this.alPedir, this.alCambiar});

  final Object? alPedir;
  final Object? alCambiar;
  CanalCodigo? canalPedido;
  String? codigoEnviado;

  @override
  Future<CodigoEnviado> pedirCodigo(CanalCodigo canal) async {
    canalPedido = canal;
    if (alPedir != null) throw alPedir!;
    return const CodigoEnviado('+591 ••••• 45');
  }

  @override
  Future<void> cambiar({
    required String codigo,
    required String passwordNueva,
  }) async {
    codigoEnviado = codigo;
    if (alCambiar != null) throw alCambiar!;
  }
}

void main() {
  CambiarContrasenaCubit crear(ContrasenaRepositorio r) =>
      CambiarContrasenaCubit(
        r,
        textoSinRed: 'sin red',
        textoCanalNoDisponible: 'canal no disponible',
      );

  test('empieza en el canal de WhatsApp, sin error ni envío', () {
    final cubit = crear(_Falso());
    expect(cubit.state.paso, PasoContrasena.canal);
    expect(cubit.state.canal, CanalCodigo.whatsapp);
    expect(cubit.state.enviando, isFalse);
    expect(cubit.state.mensaje, isNull);
  });

  test(
    'pedir el código pasa al paso del código con el destino enmascarado',
    () async {
      final repo = _Falso();
      final cubit = crear(repo)..elegirCanal(CanalCodigo.correo);
      await cubit.pedirCodigo();
      expect(repo.canalPedido, CanalCodigo.correo);
      expect(cubit.state.paso, PasoContrasena.codigo);
      expect(cubit.state.destino, '+591 ••••• 45');
      expect(cubit.state.enviando, isFalse);
    },
  );

  test(
    'sin conexión al pedir el código se queda en el canal y avisa',
    () async {
      final cubit = crear(_Falso(alPedir: const SinConexion()));
      await cubit.pedirCodigo();
      expect(cubit.state.paso, PasoContrasena.canal);
      expect(cubit.state.sinConexion, isTrue);
      expect(cubit.state.mensaje, 'sin red');
    },
  );

  test('un canal no disponible dice que elijas otro', () async {
    final cubit = crear(
      _Falso(
        alPedir: const OperacionRechazada(
          'Tuvimos un problema.',
          codigo: 503,
          motivo: 'canal_no_disponible',
        ),
      ),
    );
    await cubit.pedirCodigo();
    expect(cubit.state.paso, PasoContrasena.canal);
    expect(cubit.state.mensaje, 'canal no disponible');
  });

  test('sin destino muestra el mensaje del servidor', () async {
    final cubit = crear(
      _Falso(
        alPedir: const OperacionRechazada(
          'Tu cuenta no tiene teléfono.',
          codigo: 422,
          motivo: 'sin_destino',
        ),
      ),
    );
    await cubit.pedirCodigo();
    expect(cubit.state.mensaje, 'Tu cuenta no tiene teléfono.');
  });

  test('cambiar con un código válido termina en «listo»', () async {
    final repo = _Falso();
    final cubit = crear(repo);
    await cubit.pedirCodigo();
    await cubit.cambiar(codigo: ' 482913 ', passwordNueva: 'nueva1234');
    expect(repo.codigoEnviado, '482913');
    expect(cubit.state.paso, PasoContrasena.listo);
    expect(cubit.state.enviando, isFalse);
  });

  test('un código inválido se marca para el campo y no avanza', () async {
    final cubit = crear(
      _Falso(
        alCambiar: const OperacionRechazada(
          'El código no es válido o venció. Pide uno nuevo.',
          codigo: 422,
          motivo: 'codigo_invalido',
        ),
      ),
    );
    await cubit.pedirCodigo();
    await cubit.cambiar(codigo: '111111', passwordNueva: 'nueva1234');
    expect(cubit.state.paso, PasoContrasena.codigo);
    expect(cubit.state.codigoInvalido, isTrue);
    expect(cubit.state.mensaje, contains('Pide uno nuevo'));
  });

  test(
    'sin conexión al cambiar conserva el paso y no marca el código',
    () async {
      final cubit = crear(_Falso(alCambiar: const SinConexion()));
      await cubit.pedirCodigo();
      await cubit.cambiar(codigo: '111111', passwordNueva: 'nueva1234');
      expect(cubit.state.paso, PasoContrasena.codigo);
      expect(cubit.state.sinConexion, isTrue);
      expect(cubit.state.codigoInvalido, isFalse);
    },
  );

  test(
    'pedir otro código vuelve a elegir el canal y limpia el error',
    () async {
      final cubit = crear(_Falso(alCambiar: const SinConexion()));
      await cubit.pedirCodigo();
      await cubit.cambiar(codigo: '111111', passwordNueva: 'nueva1234');
      cubit.pedirOtro();
      expect(cubit.state.paso, PasoContrasena.canal);
      expect(cubit.state.mensaje, isNull);
      expect(cubit.state.sinConexion, isFalse);
    },
  );

  group('ReglasContrasena', () {
    test('el código son 6 números', () {
      expect(ReglasContrasena.codigo(''), isNotNull);
      expect(ReglasContrasena.codigo('12345'), isNotNull);
      expect(ReglasContrasena.codigo('12a456'), isNotNull);
      expect(ReglasContrasena.codigo('123456'), isNull);
    });

    test('la nueva pide al menos 4 caracteres, como el servidor', () {
      expect(ReglasContrasena.nueva(''), isNotNull);
      expect(ReglasContrasena.nueva('abc'), isNotNull);
      expect(ReglasContrasena.nueva('abcd'), isNull);
    });

    test('la confirmación debe coincidir', () {
      expect(ReglasContrasena.confirmacion('', 'abcd'), isNotNull);
      expect(ReglasContrasena.confirmacion('abce', 'abcd'), isNotNull);
      expect(ReglasContrasena.confirmacion('abcd', 'abcd'), isNull);
    });
  });

  group('ContrasenaDemo', () {
    final demo = ContrasenaDemo(latencia: Duration.zero);

    test('el código 000000 es incorrecto y otro de 6 dígitos sirve', () async {
      await expectLater(
        demo.cambiar(codigo: '000000', passwordNueva: 'abcd'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.motivo,
            'motivo',
            'codigo_invalido',
          ),
        ),
      );
      await demo.cambiar(codigo: '123456', passwordNueva: 'abcd');
      expect(demo.ultimaContrasena, 'abcd');
    });

    test('el canal SMS responde sin destino', () async {
      await expectLater(
        demo.pedirCodigo(CanalCodigo.sms),
        throwsA(isA<OperacionRechazada>()),
      );
    });
  });
}
