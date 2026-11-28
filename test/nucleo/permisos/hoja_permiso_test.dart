import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/permisos/domain/permiso.dart';
import 'package:agrocom_field/nucleo/permisos/presentation/hoja_permiso.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ResultadoPermiso?> abrir(
    WidgetTester tester,
    GestorPermisosEnMemoria gestor,
    PermisoApp permiso, {
    double escala = 1,
  }) async {
    ResultadoPermiso? resultado;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => resultado =
                    await pedirPermisoConExplicacion(context, gestor, permiso),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return resultado;
  }

  testWidgets('explica el motivo antes de pedir y concede al continuar', (
    tester,
  ) async {
    final gestor = GestorPermisosEnMemoria();
    await abrir(tester, gestor, PermisoApp.camara);
    expect(find.text('Usar la cámara'), findsOneWidget);
    expect(gestor.pedidos, isEmpty, reason: 'aún no se pregunta al sistema');

    await tester.tap(find.byKey(const Key('permiso-continuar')));
    await tester.pumpAndSettle();
    expect(gestor.pedidos, [PermisoApp.camara]);
  });

  testWidgets('«Ahora no» cierra sin pedir', (tester) async {
    final gestor = GestorPermisosEnMemoria();
    await abrir(tester, gestor, PermisoApp.ubicacion);
    await tester.tap(find.byKey(const Key('permiso-ahora-no')));
    await tester.pumpAndSettle();
    expect(gestor.pedidos, isEmpty);
    expect(find.text('Compartir tu ubicación'), findsNothing);
  });

  testWidgets('denegado para siempre ofrece abrir ajustes', (tester) async {
    final gestor = GestorPermisosEnMemoria(
      estados: {PermisoApp.notificaciones: EstadoPermiso.denegadoParaSiempre},
    );
    await abrir(tester, gestor, PermisoApp.notificaciones);
    expect(find.text('Permiso desactivado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('permiso-abrir-ajustes')));
    await tester.pumpAndSettle();
    expect(gestor.ajustesAbiertos, [PermisoApp.notificaciones]);
  });

  testWidgets('con el texto al 200 % no desborda y mantiene los botones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await abrir(
      tester,
      GestorPermisosEnMemoria(),
      PermisoApp.ubicacion,
      escala: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('permiso-continuar')), findsOneWidget);
    final alto = tester
        .getSize(find.byKey(const Key('permiso-ahora-no')))
        .height;
    expect(alto, greaterThanOrEqualTo(56));
  });
}
