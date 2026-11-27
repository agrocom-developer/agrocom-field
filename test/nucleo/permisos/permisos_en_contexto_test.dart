// Ningún permiso se pide al arrancar: la cámara, la ubicación y los avisos se
// piden en el punto de uso, después de explicar para qué (ADR 0026).

import 'dart:io';

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/permisos/domain/permiso.dart';
import 'package:agrocom_field/nucleo/permisos/presentation/hoja_permiso.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _montar(
  WidgetTester tester, {
  required GestorPermisos? gestor,
  required void Function(bool) alResolver,
}) async {
  Widget home = Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async =>
              alResolver(await permitirCamaraConExplicacion(context)),
          child: const Text('tomar foto'),
        ),
      ),
    ),
  );
  if (gestor != null) {
    home = RepositoryProvider<GestorPermisos>.value(value: gestor, child: home);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(),
      home: home,
    ),
  );
}

void main() {
  group('la cámara se pide al usarla', () {
    testWidgets('explica antes del aviso del sistema y concede al continuar', (
      tester,
    ) async {
      final gestor = GestorPermisosEnMemoria();
      bool? resultado;
      await _montar(tester, gestor: gestor, alResolver: (r) => resultado = r);
      expect(gestor.pedidos, isEmpty, reason: 'al montar no se pide nada');

      await tester.tap(find.text('tomar foto'));
      await tester.pumpAndSettle();
      expect(find.text('Usar la cámara'), findsOneWidget);
      expect(gestor.pedidos, isEmpty, reason: 'primero se explica');

      await tester.tap(find.byKey(const Key('permiso-continuar')));
      await tester.pumpAndSettle();
      expect(gestor.pedidos, [PermisoApp.camara]);
      expect(resultado, isTrue);
    });

    testWidgets('«Ahora no» no abre la cámara ni molesta al sistema', (
      tester,
    ) async {
      final gestor = GestorPermisosEnMemoria();
      bool? resultado;
      await _montar(tester, gestor: gestor, alResolver: (r) => resultado = r);
      await tester.tap(find.text('tomar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('permiso-ahora-no')));
      await tester.pumpAndSettle();
      expect(gestor.pedidos, isEmpty);
      expect(resultado, isFalse);
    });

    testWidgets('con el permiso ya concedido sigue sin volver a preguntar', (
      tester,
    ) async {
      final gestor = GestorPermisosEnMemoria(
        estados: {PermisoApp.camara: EstadoPermiso.concedido},
      );
      bool? resultado;
      await _montar(tester, gestor: gestor, alResolver: (r) => resultado = r);
      await tester.tap(find.text('tomar foto'));
      await tester.pumpAndSettle();
      expect(find.text('Usar la cámara'), findsNothing);
      expect(gestor.pedidos, isEmpty);
      expect(resultado, isTrue);
    });

    testWidgets('sin gestor en el árbol no interpone nada', (tester) async {
      bool? resultado;
      await _montar(tester, gestor: null, alResolver: (r) => resultado = r);
      await tester.tap(find.text('tomar foto'));
      await tester.pumpAndSettle();
      expect(resultado, isTrue);
    });
  });

  group('al arrancar no se pide ningún permiso', () {
    // Los puntos de arranque y de composición no deben tocar el gestor de
    // permisos ni los plugins que muestran el aviso del sistema.
    const arranque = [
      'lib/main_cliente.dart',
      'lib/main_piloto.dart',
      'lib/cliente/app_cliente.dart',
      'lib/cliente/acceso/presentation/puerta_acceso_cliente.dart',
      'lib/cliente/acceso/presentation/arranque_cubit.dart',
      'lib/nucleo/di/composicion_proveedor.dart',
      'lib/nucleo/marketplace/proveedor/acceso/presentation/app_proveedor.dart',
      'lib/nucleo/marketplace/proveedor/acceso/presentation/acceso_cubit.dart',
    ];
    const prohibidos = [
      'pedirPermiso',
      'requestPermission',
      'requestNotificationsPermission',
      'requestPermissions',
      'pedirPermisoConExplicacion',
      'permitirCamaraConExplicacion',
      '.pedir(',
    ];

    for (final ruta in arranque) {
      test(ruta, () {
        final fuente = File(ruta).readAsStringSync();
        for (final p in prohibidos) {
          expect(
            fuente.contains(p),
            isFalse,
            reason: '$ruta no debe pedir permisos al arrancar ($p)',
          );
        }
      });
    }
  });
}
