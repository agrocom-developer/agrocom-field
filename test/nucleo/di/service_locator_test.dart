// Etapa 3 de TE-19: `configurarDependencias` deja `DisparadorSync`
// registrado en `getIt`, listo para instanciarse en los dos flavors — sin
// resolverlo (`registerLazySingleton` no lo construye todavía), así que
// este test no necesita mockear los canales de plataforma de sus
// dependencias transitivas (secure storage, shared preferences,
// notificaciones...), solo el de `path_provider` que `configurarDependencias`
// sí resuelve de entrada (ver `directorio_evidencias_test.dart`).

import 'dart:io';

import 'package:agrocom_field/nucleo/di/service_locator.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/sync/disparador_sync.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalDocumentos = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documentosFalsos;

  setUp(() {
    documentosFalsos = Directory.systemTemp.createTempSync('documentos_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalDocumentos, (llamada) async {
          if (llamada.method == 'getApplicationDocumentsDirectory') {
            return documentosFalsos.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalDocumentos, null);
    if (documentosFalsos.existsSync()) {
      documentosFalsos.deleteSync(recursive: true);
    }
    await getIt.reset();
  });

  for (final flavor in Flavor.values) {
    test('configurarDependencias(flavor: $flavor) deja DisparadorSync listo '
        'para instanciarse', () async {
      await configurarDependencias(flavor: flavor);

      expect(getIt.isRegistered<DisparadorSync>(), isTrue);
    });
  }
}
