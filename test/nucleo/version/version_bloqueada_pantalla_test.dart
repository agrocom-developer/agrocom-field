// Etapa 2 de HU-20: `VersionBloqueadaPantalla` en aislamiento — muestra la
// versión mínima y el `url_descarga` recibidos, y no ofrece vía de escape
// (`PopScope.canPop == false`).

import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:agrocom_field/nucleo/version/version_bloqueada_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _minima = VersionApk(
  version: '1.5.0',
  versionCode: 15000,
  urlDescarga: 'https://agrocom.example/apk/1.5.0',
);

void main() {
  testWidgets('muestra la versión mínima requerida y el url_descarga', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: VersionBloqueadaPantalla(minima: _minima)),
    );

    expect(find.textContaining('1.5.0'), findsWidgets);
    expect(find.text(_minima.urlDescarga), findsOneWidget);
  });

  testWidgets('no ofrece vía de escape: PopScope no deja hacer pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: VersionBloqueadaPantalla(minima: _minima)),
    );

    final popScope = tester.widget<PopScope>(
      find.byKey(const Key('version_bloqueada_pantalla')),
    );
    expect(popScope.canPop, isFalse);
  });
}
