import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/permisos/permiso_app.dart';
import 'package:agrocom_field/nucleo/permisos/permisos_servicio.dart';
import 'package:agrocom_field/nucleo/permisos/presentation/asegurar_permiso.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool?> _abrir(
  WidgetTester tester,
  PermisosServicioFalso servicio,
  PermisoApp permiso,
) async {
  bool? resultado;
  await tester.pumpWidget(
    MaterialApp(
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('abrir'),
              onPressed: () async => resultado = await asegurarPermiso(
                context,
                permiso,
                servicio: servicio,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('abrir')));
  await tester.pumpAndSettle();
  return resultado;
}

void main() {
  testWidgets('concedido: sigue sin mostrar nada ni pedir', (tester) async {
    final s = PermisosServicioFalso(inicial: EstadoPermiso.concedido);
    final r = await _abrir(tester, s, PermisoApp.camara);
    expect(r, isTrue);
    expect(find.byKey(const Key('permiso-motivo')), findsNothing);
    expect(s.solicitados, isEmpty);
  });

  testWidgets('fotos no requiere permiso: nunca pregunta', (tester) async {
    final s = PermisosServicioFalso();
    final r = await _abrir(tester, s, PermisoApp.fotos);
    expect(r, isTrue);
    expect(s.solicitados, isEmpty);
  });

  testWidgets('explica el motivo antes de pedir y sigue si lo conceden', (
    tester,
  ) async {
    final s = PermisosServicioFalso();
    await _abrir(tester, s, PermisoApp.camara);
    expect(find.byKey(const Key('permiso-motivo')), findsOneWidget);
    expect(find.text('Usar la cámara'), findsOneWidget);
    expect(s.solicitados, isEmpty, reason: 'primero el motivo');
    await tester.tap(find.byKey(const Key('permiso-continuar')));
    await tester.pumpAndSettle();
    expect(s.solicitados, [PermisoApp.camara]);
  });

  testWidgets('«Ahora no» no llega a pedir al sistema', (tester) async {
    final s = PermisosServicioFalso();
    await _abrir(tester, s, PermisoApp.ubicacion);
    await tester.tap(find.byKey(const Key('permiso-ahora-no')));
    await tester.pumpAndSettle();
    expect(s.solicitados, isEmpty);
  });

  testWidgets('si lo niegan explica qué pierde y no ofrece ajustes', (
    tester,
  ) async {
    final s = PermisosServicioFalso(alSolicitar: EstadoPermiso.denegado);
    await _abrir(tester, s, PermisoApp.camara);
    await tester.tap(find.byKey(const Key('permiso-continuar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('permiso-denegado')), findsOneWidget);
    expect(find.byKey(const Key('permiso-abrir-ajustes')), findsNothing);
  });

  testWidgets('denegado para siempre: ofrece abrir los ajustes', (
    tester,
  ) async {
    final s = PermisosServicioFalso(inicial: EstadoPermiso.denegadoParaSiempre);
    await _abrir(tester, s, PermisoApp.ubicacion);
    expect(find.byKey(const Key('permiso-motivo')), findsNothing);
    await tester.tap(find.byKey(const Key('permiso-abrir-ajustes')));
    await tester.pumpAndSettle();
    expect(s.ajustesAbiertos, 1);
    expect(s.solicitados, isEmpty);
  });

  test('traduce los estados de permission_handler', () {
    expect(
      PermisosServicioReal.traducir(PermissionStatus.granted),
      EstadoPermiso.concedido,
    );
    expect(
      PermisosServicioReal.traducir(PermissionStatus.limited),
      EstadoPermiso.concedido,
    );
    expect(
      PermisosServicioReal.traducir(PermissionStatus.denied),
      EstadoPermiso.denegado,
    );
    expect(
      PermisosServicioReal.traducir(PermissionStatus.permanentlyDenied),
      EstadoPermiso.denegadoParaSiempre,
    );
    expect(
      PermisosServicioReal.traducir(PermissionStatus.restricted),
      EstadoPermiso.restringido,
    );
  });
}
