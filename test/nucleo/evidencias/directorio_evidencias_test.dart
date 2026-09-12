// `resolverDirectorioEvidencias` mockeando el `MethodChannel` real de
// `path_provider` (canal `plugins.flutter.io/path_provider`) — sin
// dispositivo ni emulador, mismo criterio que el resto de los plugins
// nativos de este repo (`linterna_controlador_test.dart`,
// `notificador_local_plugin_test.dart`).

import 'dart:io';

import 'package:agrocom_field/nucleo/evidencias/directorio_evidencias.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documentosFalsos;

  setUp(() {
    documentosFalsos = Directory.systemTemp.createTempSync('documentos_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          if (llamada.method == 'getApplicationDocumentsDirectory') {
            return documentosFalsos.path;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
    if (documentosFalsos.existsSync()) {
      documentosFalsos.deleteSync(recursive: true);
    }
  });

  test(
    'crea y devuelve la subcarpeta "evidencias" dentro de documentos',
    () async {
      final directorio = await resolverDirectorioEvidencias();

      expect(directorio.path, '${documentosFalsos.path}/evidencias');
      expect(directorio.existsSync(), isTrue);
    },
  );

  test('no falla si la subcarpeta ya existe', () async {
    await resolverDirectorioEvidencias();

    final directorio = await resolverDirectorioEvidencias();

    expect(directorio.existsSync(), isTrue);
  });
}
