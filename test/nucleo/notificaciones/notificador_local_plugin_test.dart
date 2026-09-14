// Etapa 1 de HU-62: `NotificadorLocalPlugin` mockeando el `MethodChannel`
// real del plugin (`dexterous.com/flutter/local_notifications`) — sin
// dispositivo ni emulador, mismo criterio que cualquier otro test de este
// repo (ADR 0005: testeable sin emulador). Se registra manualmente
// `AndroidFlutterLocalNotificationsPlugin` como implementación de
// plataforma porque en `flutter test` puro (sin widget pump) el registro
// automático de plugins no corre.

import 'package:agrocom_field/nucleo/notificaciones/notificador_local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('dexterous.com/flutter/local_notifications');
  final llamadas = <MethodCall>[];

  setUp(() {
    llamadas.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          llamadas.add(llamada);
          switch (llamada.method) {
            case 'initialize':
              return true;
            case 'requestNotificationsPermission':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test(
    'pedirPermiso inicializa el plugin y pide el permiso de Android',
    () async {
      final notificador = NotificadorLocalPlugin();

      final concedido = await notificador.pedirPermiso();

      expect(concedido, isTrue);
      expect(llamadas.map((l) => l.method).toList(), [
        'initialize',
        'requestNotificationsPermission',
      ]);
    },
  );

  test(
    'mostrar inicializa el plugin una sola vez y muestra la notificación',
    () async {
      final notificador = NotificadorLocalPlugin();

      await notificador.mostrar(
        id: 7,
        titulo: 'Nueva orden sincronizada',
        cuerpo: 'Orden #3 — lote L-01',
      );
      await notificador.mostrar(
        id: 8,
        titulo: 'Otra orden',
        cuerpo: 'Otro detalle',
      );

      expect(llamadas.map((l) => l.method).toList(), [
        'initialize',
        'show',
        'show',
      ]);
      final primerShow = llamadas[1];
      expect(primerShow.arguments['id'], 7);
      expect(primerShow.arguments['title'], 'Nueva orden sincronizada');
      expect(primerShow.arguments['body'], 'Orden #3 — lote L-01');
    },
  );
}
