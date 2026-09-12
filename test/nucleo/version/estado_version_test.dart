// Comparación pura de HU-20 (bloqueo por versión mínima): sin ApiClient,
// sin async — cubre los tres casos de `evaluarEstadoVersion` (el cuarto,
// "error de red no bloquea", vive en `version_repository_test.dart` porque
// depende de la llamada a la API).

import 'package:agrocom_field/nucleo/version/estado_version.dart';
import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const minima = VersionApk(
    version: '1.4.0',
    versionCode: 14000,
    urlDescarga: 'https://github.com/agrocom/agrocom-field/releases/v1.4.0',
  );

  test('minima null: permitida sin importar el version_code instalado', () {
    expect(
      evaluarEstadoVersion(minima: null, versionCodeInstalado: 1),
      const VersionPermitida(),
    );
  });

  test('version_code igual a la minima: permitida', () {
    expect(
      evaluarEstadoVersion(minima: minima, versionCodeInstalado: 14000),
      const VersionPermitida(),
    );
  });

  test('version_code por encima de la minima: permitida', () {
    expect(
      evaluarEstadoVersion(minima: minima, versionCodeInstalado: 14001),
      const VersionPermitida(),
    );
  });

  test('version_code por debajo de la minima: bloqueada con la minima', () {
    expect(
      evaluarEstadoVersion(minima: minima, versionCodeInstalado: 13999),
      const VersionBloqueada(minima),
    );
  });
}
