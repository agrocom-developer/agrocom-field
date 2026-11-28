import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Permisos por flavor (docs/seguridad/permisos.md). Google Play penaliza los
/// permisos declarados y no usados: el cliente no usa ubicación, linterna ni
/// avisos locales, y esos permisos viven solo en `src/piloto`. Lee los
/// manifiestos fuente (el fusionado depende de los plugins y de un build).
void main() {
  String leer(String ruta) => File(ruta).readAsStringSync();

  final principal = leer('android/app/src/main/AndroidManifest.xml');
  final cliente = leer('android/app/src/cliente/AndroidManifest.xml');
  final piloto = leer('android/app/src/piloto/AndroidManifest.xml');

  /// Nombres de `<uses-permission>` declarados, sin los que llevan
  /// `tools:node="remove"` (esos los quita el fusionador de manifiestos).
  Set<String> declarados(String manifest) {
    final sinComentarios = manifest.replaceAll(
      RegExp(r'<!--.*?-->', dotAll: true),
      '',
    );
    final etiqueta = RegExp(r'<uses-permission\b[^>]*>', dotAll: true);
    final nombre = RegExp(r'android:name="([^"]+)"');
    return {
      for (final m in etiqueta.allMatches(sinComentarios))
        if (!m.group(0)!.contains('tools:node="remove"'))
          nombre.firstMatch(m.group(0)!)!.group(1)!,
    };
  }

  Set<String> quitados(String manifest) {
    final etiqueta = RegExp(r'<[^<>]*tools:node="remove"[^<>]*>', dotAll: true);
    final nombre = RegExp(r'android:name="([^"]+)"');
    return {
      for (final m in etiqueta.allMatches(manifest))
        nombre.firstMatch(m.group(0)!)!.group(1)!,
    };
  }

  const ubicacion = {
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
  };

  test('el manifest común solo declara INTERNET y CAMERA', () {
    expect(declarados(principal), {
      'android.permission.INTERNET',
      'android.permission.CAMERA',
    });
    // Declarar CAMERA no debe excluir dispositivos sin cámara de Play Store.
    expect(principal, contains('android.hardware.camera"'));
    expect(principal, contains('android.hardware.camera.autofocus'));
    expect(principal, isNot(contains('android.hardware.camera.flash')));
  });

  test('el cliente no declara ubicación en ningún manifest fuente', () {
    for (final permiso in ubicacion) {
      expect(principal, isNot(contains(permiso)));
      expect(declarados(cliente), isNot(contains(permiso)));
    }
  });

  test('el cliente no declara linterna ni avisos locales', () {
    expect(declarados(cliente), isEmpty);
    expect(cliente, isNot(contains('android.hardware.camera.flash')));
    expect(
      quitados(cliente),
      containsAll({
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.VIBRATE',
        'com.baseflow.geolocator.GeolocatorLocationService',
      }),
    );
  });

  test('el piloto declara ubicación, avisos y linterna opcional', () {
    expect(
      declarados(piloto),
      containsAll({
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.POST_NOTIFICATIONS',
      }),
    );
    expect(
      declarados(piloto),
      isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
    );
    expect(piloto, contains('android.hardware.camera.flash'));
    expect(piloto, contains('android:required="false"'));
  });

  test(
    'CAMERA solo está en el manifest común; nadie declara almacenamiento amplio',
    () {
      for (final conComentarios in [cliente, piloto]) {
        final manifest = conComentarios.replaceAll(
          RegExp(r'<!--.*?-->', dotAll: true),
          '',
        );
        expect(manifest, isNot(contains('android.permission.CAMERA')));
      }
      for (final conComentarios in [principal, cliente, piloto]) {
        final manifest = conComentarios.replaceAll(
          RegExp(r'<!--.*?-->', dotAll: true),
          '',
        );
        expect(manifest, isNot(contains('READ_EXTERNAL_STORAGE')));
        expect(manifest, isNot(contains('WRITE_EXTERNAL_STORAGE')));
        expect(manifest, isNot(contains('READ_MEDIA_')));
      }
    },
  );

  group('iOS (Info.plist compartido por los dos flavors)', () {
    final plist = leer('ios/Runner/Info.plist');

    String? valor(String clave) => RegExp(
      '<key>$clave</key>\\s*<string>([^<]*)</string>',
    ).firstMatch(plist)?.group(1);

    for (final clave in [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSLocationWhenInUseUsageDescription',
      'NSFaceIDUsageDescription',
    ]) {
      test('$clave tiene texto de propósito en español', () {
        final texto = valor(clave);
        expect(texto, isNotNull);
        expect(texto!.length, greaterThan(40));
        expect(texto, isNot(contains('Agrocom Field')));
        expect(texto, startsWith('DronAgro'));
      });
    }

    test('no pide ubicación permanente ni micrófono', () {
      expect(plist, isNot(contains('NSLocationAlwaysAndWhenInUse')));
      expect(plist, isNot(contains('NSLocationAlwaysUsageDescription')));
      expect(plist, isNot(contains('NSMicrophoneUsageDescription')));
    });

    test('el único modo en segundo plano es remote-notification', () {
      final modos = RegExp(
        r'<key>UIBackgroundModes</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)?.group(1);
      expect(modos, isNotNull);
      final valores = RegExp(
        r'<string>([^<]*)</string>',
      ).allMatches(modos!).map((m) => m.group(1)).toList();
      expect(valores, ['remote-notification']);
    });

    test(
      'el texto de ubicación declara también el uso puntual del auxilio',
      () {
        expect(
          valor('NSLocationWhenInUseUsageDescription'),
          contains('auxilio'),
        );
      },
    );

    test(
      'el manifiesto de privacidad existe, no rastrea y está en el proyecto',
      () {
        final privacidad = leer('ios/Runner/PrivacyInfo.xcprivacy');
        expect(
          RegExp(
            r'<key>NSPrivacyTracking</key>\s*<false/>',
          ).hasMatch(privacidad),
          isTrue,
        );
        expect(privacidad, contains('NSPrivacyAccessedAPITypes'));
        expect(
          leer('ios/Runner.xcodeproj/project.pbxproj'),
          contains('PrivacyInfo.xcprivacy in Resources'),
        );
      },
    );
  });
}
