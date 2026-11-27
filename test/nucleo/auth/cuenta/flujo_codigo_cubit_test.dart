// El recorrido «elegir canal, recibir el código, confirmarlo»: canal caído
// (503), cuenta regresiva de reenvío (429 y envío exitoso) y confirmación.

import 'package:agrocom_field/nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/flujo_codigo_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const _paso = Duration(milliseconds: 4);

Future<void> _esperar(int pasos) =>
    Future<void>.delayed(_paso * pasos + const Duration(milliseconds: 40));

void main() {
  FlujoCodigoCubit crear({
    Future<CodigoEnviado?> Function(CanalCodigo)? pedir,
    Future<Object?> Function(String, String?)? confirmar,
    List<CanalCodigo> canales = CanalCodigo.values,
    Duration espera = const Duration(seconds: 3),
  }) => FlujoCodigoCubit(
    pedir: pedir ?? (_) async => const CodigoEnviado(destino: '+591 ••••• 45'),
    confirmar: confirmar ?? (_, _) async => 'ok',
    canales: canales,
    esperaReenvio: espera,
    esperaPorDefectoEn429: const Duration(seconds: 2),
    paso: _paso,
  );

  test(
    'enviar pasa a escribir el código y arranca la cuenta regresiva',
    () async {
      final c = crear();
      await c.enviar(CanalCodigo.whatsapp);
      expect(c.state.etapa, EtapaCodigo.escribirCodigo);
      expect(c.state.canal, CanalCodigo.whatsapp);
      expect(c.state.destino, '+591 ••••• 45');
      expect(c.state.reenvioEn, inInclusiveRange(1, 3));
      expect(c.state.limitado, isFalse);
      expect(c.state.puedeReenviar, isFalse);
      await _esperar(3);
      expect(c.state.reenvioEn, 0);
      expect(c.state.puedeReenviar, isTrue);
      await c.close();
    },
  );

  test(
    'un canal sin red de envío (503) queda marcado y se ofrece otro',
    () async {
      final c = crear(
        pedir: (canal) async {
          if (canal == CanalCodigo.whatsapp) {
            throw const CuentaCanalNoDisponible(CanalCodigo.whatsapp);
          }
          return null;
        },
      );
      await c.enviar(CanalCodigo.whatsapp);
      expect(c.state.etapa, EtapaCodigo.elegirCanal);
      expect(c.state.canalesCaidos, {CanalCodigo.whatsapp});
      expect(c.state.falla, isA<CuentaCanalNoDisponible>());
      expect(c.disponibles, [CanalCodigo.sms, CanalCodigo.correo]);
      // Sin esperar: elegir otro canal funciona de inmediato.
      await c.enviar(CanalCodigo.correo);
      expect(c.state.etapa, EtapaCodigo.escribirCodigo);
      expect(c.state.canal, CanalCodigo.correo);
      expect(c.state.falla, isNull);
      await c.close();
    },
  );

  test('429 bloquea todos los canales con la espera de Retry-After', () async {
    var llamadas = 0;
    final c = crear(
      pedir: (_) async {
        llamadas++;
        throw const CuentaLimiteExcedido(espera: Duration(seconds: 5));
      },
    );
    await c.enviar(CanalCodigo.sms);
    expect(c.state.falla, isA<CuentaLimiteExcedido>());
    expect(c.state.limitado, isTrue);
    expect(c.state.reenvioEn, inInclusiveRange(1, 5));
    await c.enviar(CanalCodigo.correo);
    expect(llamadas, 1, reason: 'durante la espera no se vuelve a pedir');
    await _esperar(5);
    expect(c.state.reenvioEn, 0);
    expect(c.state.limitado, isFalse);
    await c.close();
  });

  test('429 sin Retry-After usa la espera por defecto', () async {
    final c = crear(pedir: (_) async => throw const CuentaLimiteExcedido());
    await c.enviar(CanalCodigo.sms);
    expect(c.state.reenvioEn, inInclusiveRange(1, 2));
    await c.close();
  });

  test('reenviar solo funciona cuando terminó la cuenta regresiva', () async {
    var llamadas = 0;
    final c = crear(
      pedir: (_) async {
        llamadas++;
        return null;
      },
      espera: const Duration(seconds: 2),
    );
    await c.enviar(CanalCodigo.sms);
    await c.reenviar();
    expect(llamadas, 1);
    await _esperar(2);
    await c.reenviar();
    expect(llamadas, 2);
    await c.close();
  });

  test('cambiarCanal vuelve a elegir y conserva los canales caídos', () async {
    final c = crear(
      pedir: (canal) async {
        if (canal == CanalCodigo.sms) {
          throw const CuentaCanalNoDisponible(CanalCodigo.sms);
        }
        return null;
      },
    );
    await c.enviar(CanalCodigo.sms);
    await c.enviar(CanalCodigo.whatsapp);
    c.cambiarCanal();
    expect(c.state.etapa, EtapaCodigo.elegirCanal);
    expect(c.state.canalesCaidos, {CanalCodigo.sms});
    await c.close();
  });

  test('confirmar bien deja el resultado y termina', () async {
    String? recibido;
    final c = crear(
      confirmar: (codigo, contrasena) async {
        recibido = '$codigo/$contrasena';
        return 'rosa.c';
      },
    );
    await c.enviar(CanalCodigo.correo);
    await c.confirmarCodigo(' 123456 ', contrasenaNueva: 'abcd');
    expect(recibido, '123456/abcd');
    expect(c.state.etapa, EtapaCodigo.listo);
    expect(c.state.resultado, 'rosa.c');
    expect(c.state.reenvioEn, 0);
    await c.close();
  });

  test('un código inválido deja la falla y permite reintentar', () async {
    var intentos = 0;
    final c = crear(
      confirmar: (codigo, _) async {
        intentos++;
        if (codigo != '000000') throw const CuentaCodigoInvalido();
        return null;
      },
    );
    await c.enviar(CanalCodigo.sms);
    await c.confirmarCodigo('111111');
    expect(c.state.etapa, EtapaCodigo.escribirCodigo);
    expect(c.state.falla, isA<CuentaCodigoInvalido>());
    c.limpiarFalla();
    expect(c.state.falla, isNull);
    await c.confirmarCodigo('000000');
    expect(intentos, 2);
    expect(c.state.etapa, EtapaCodigo.listo);
    await c.close();
  });

  test('sin conexión al confirmar conserva la etapa', () async {
    final c = crear(confirmar: (_, _) async => throw const CuentaSinConexion());
    await c.enviar(CanalCodigo.sms);
    await c.confirmarCodigo('123456');
    expect(c.state.etapa, EtapaCodigo.escribirCodigo);
    expect(c.state.falla, isA<CuentaSinConexion>());
    expect(c.state.confirmando, isFalse);
    await c.close();
  });

  test('ReglasCodigo exige exactamente 6 dígitos', () {
    expect(ReglasCodigo.validar(''), isNotNull);
    expect(ReglasCodigo.validar('12345'), isNotNull);
    expect(ReglasCodigo.validar('12345a'), isNotNull);
    expect(ReglasCodigo.validar('1234567'), isNotNull);
    expect(ReglasCodigo.validar('482913'), isNull);
    expect(ReglasCodigo.validar(' 482913 '), isNull);
  });
}
