import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifica el manifest principal de Android: es el que usa la build release,
/// y sin INTERNET la app no sincroniza; sin las banderas de seguridad, el
/// release aceptaría tráfico en claro o copias de respaldo de la base local.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('declara el permiso INTERNET en el manifest principal', () {
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('prohíbe respaldo y tráfico en claro en release', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, contains('@xml/network_security_config'));
  });

  test('la configuración de red principal no permite cleartext', () {
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();
    expect(config, contains('cleartextTrafficPermitted="false"'));
    expect(config, isNot(contains('cleartextTrafficPermitted="true"')));
  });

  test('solo debug permite http', () {
    final config = File(
      'android/app/src/debug/res/xml/network_security_config.xml',
    ).readAsStringSync();
    expect(config, contains('cleartextTrafficPermitted="true"'));
  });
}
