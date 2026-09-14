// Etapa 1 de HU-68: `LinternaControladorTorchLight` mockeando el
// `MethodChannel` real del plugin `torch_light`
// (`com.svprdga.torchlight/main`) — sin dispositivo ni emulador, mismo
// criterio que `test/nucleo/notificaciones/notificador_local_plugin_test.dart`.

import 'package:agrocom_field/nucleo/linterna/linterna_controlador.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torch_light/torch_light.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('com.svprdga.torchlight/main');
  final llamadas = <MethodCall>[];
  Object? Function(MethodCall) responder = (_) => null;

  setUp(() {
    llamadas.clear();
    responder = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          llamadas.add(llamada);
          return responder(llamada);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test(
    'disponible consulta al canal si el dispositivo tiene linterna',
    () async {
      responder = (_) => true;
      final controlador = LinternaControladorTorchLight();

      final resultado = await controlador.disponible();

      expect(resultado, isTrue);
      expect(llamadas.single.method, 'torch_available');
    },
  );

  test('encender invoca enable_torch en el canal', () async {
    final controlador = LinternaControladorTorchLight();

    await controlador.encender();

    expect(llamadas.single.method, 'enable_torch');
  });

  test('apagar invoca disable_torch en el canal', () async {
    final controlador = LinternaControladorTorchLight();

    await controlador.apagar();

    expect(llamadas.single.method, 'disable_torch');
  });

  test(
    'encender propaga la excepción tipada si el dispositivo no tiene linterna',
    () async {
      responder = (_) =>
          throw PlatformException(code: 'enable_torch_not_available');
      final controlador = LinternaControladorTorchLight();

      expect(
        controlador.encender(),
        throwsA(isA<EnableTorchNotAvailableException>()),
      );
    },
  );
}
