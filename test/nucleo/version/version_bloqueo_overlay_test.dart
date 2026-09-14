// Etapa 2 de HU-20: `VersionBloqueoOverlay` en aislamiento — tapa el
// contenido cuando el estado emitido es `VersionBloqueada` y lo deja pasar
// en cualquier otro caso (permitida, o sin ninguna emisión todavía).

import 'dart:async';

import 'package:agrocom_field/nucleo/version/estado_version.dart';
import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:agrocom_field/nucleo/version/version_bloqueo_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _minima = VersionApk(
  version: '3.0.0',
  versionCode: 30000,
  urlDescarga: 'https://agrocom.example/apk/3.0.0',
);

void main() {
  testWidgets('sin emisión todavía, muestra el contenido sin tapar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VersionBloqueoOverlay(
          estadoVersion: const Stream<EstadoVersion>.empty(),
          child: const Text('contenido'),
        ),
      ),
    );

    expect(find.text('contenido'), findsOneWidget);
    expect(find.byKey(const Key('version_bloqueada_pantalla')), findsNothing);
  });

  testWidgets('VersionPermitida no tapa el contenido', (tester) async {
    final controlador = StreamController<EstadoVersion>();
    addTearDown(controlador.close);

    await tester.pumpWidget(
      MaterialApp(
        home: VersionBloqueoOverlay(
          estadoVersion: controlador.stream,
          child: const Text('contenido'),
        ),
      ),
    );

    controlador.add(const VersionPermitida());
    await tester.pumpAndSettle();

    expect(find.text('contenido'), findsOneWidget);
    expect(find.byKey(const Key('version_bloqueada_pantalla')), findsNothing);
  });

  testWidgets(
    'VersionBloqueada tapa el contenido con VersionBloqueadaPantalla',
    (tester) async {
      final controlador = StreamController<EstadoVersion>();
      addTearDown(controlador.close);

      await tester.pumpWidget(
        MaterialApp(
          home: VersionBloqueoOverlay(
            estadoVersion: controlador.stream,
            child: const Text('contenido'),
          ),
        ),
      );

      controlador.add(const VersionBloqueada(_minima));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('version_bloqueada_pantalla')),
        findsOneWidget,
      );
      expect(find.text(_minima.urlDescarga), findsOneWidget);
    },
  );
}
