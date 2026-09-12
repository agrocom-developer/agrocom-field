// Etapa 1 de HU-20: `VersionInstaladaPackageInfo` mockeando el
// `MethodChannel` real del plugin (`dev.fluttercommunity.plus/package_info`)
// — sin dispositivo ni emulador, mismo criterio que
// `test/nucleo/notificaciones/notificador_local_plugin_test.dart`.

import 'package:agrocom_field/nucleo/version/version_instalada.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('dev.fluttercommunity.plus/package_info');

  Future<void> mockearBuildNumber(String buildNumber) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          if (llamada.method == 'getAll') {
            return {
              'appName': 'Agrocom Field',
              'packageName': 'com.agrocom.field',
              'version': '1.4.0',
              'buildNumber': buildNumber,
              'buildSignature': '',
            };
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test(
    'versionCode parsea el buildNumber reportado por la plataforma',
    () async {
      await mockearBuildNumber('14002');

      final versionCode = await VersionInstaladaPackageInfo().versionCode();

      expect(versionCode, 14002);
    },
  );
}
