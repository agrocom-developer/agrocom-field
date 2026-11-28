import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations_es.dart';
import 'domain/canal_aviso.dart';
import 'domain/textos_canal.dart';

/// Notificaciones locales generadas por reglas que corren en el dispositivo
/// (HU-62) — sin servidor push ni FCM. Abstracta para poder fakear en tests
/// sin canal de plataforma real, mismo patrón que `nucleo/auth`.
abstract class NotificadorLocal {
  /// Pide el permiso de notificaciones al sistema operativo (Android 13+,
  /// `POST_NOTIFICATIONS` en runtime). Devuelve si quedó concedido.
  Future<bool> pedirPermiso();

  /// Muestra una notificación en el [canal] indicado (canal de Android y
  /// categoría de iOS propios). [carga] dice qué abrir al tocarla
  /// (`recurso_tipo:recurso_id`).
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    CanalAviso canal = CanalAviso.cuenta,
    String? carga,
  });
}

/// Envuelve `FlutterLocalNotificationsPlugin`. Cada [CanalAviso] tiene su
/// canal de Android (que el sistema deja silenciar por separado) y su
/// categoría de iOS. Funciona igual con Firebase apagado: las notificaciones
/// salen de la bandeja del servidor y no de un push.
class NotificadorLocalPlugin implements NotificadorLocal {
  NotificadorLocalPlugin([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _inicializado = false;

  Future<void> _asegurarInicializado() async {
    if (_inicializado) return;
    final configuracion = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      // El permiso se pide en contexto (con su explicación), no al iniciar.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          for (final c in CanalAviso.values)
            DarwinNotificationCategory(c.codigo),
        ],
      ),
    );
    await _plugin.initialize(settings: configuracion);
    _inicializado = true;
  }

  @override
  Future<bool> pedirPermiso() async {
    await _asegurarInicializado();
    final concedido = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return concedido ?? false;
  }

  @override
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    CanalAviso canal = CanalAviso.cuenta,
    String? carga,
  }) async {
    await _asegurarInicializado();
    final textos = AppLocalizationsEs();
    final detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        canal.codigo,
        canal.nombre(textos),
        channelDescription: canal.descripcion(textos),
        importance: switch (canal.nivel) {
          NivelAviso.alto => Importance.high,
          NivelAviso.medio => Importance.defaultImportance,
        },
        priority: switch (canal.nivel) {
          NivelAviso.alto => Priority.high,
          NivelAviso.medio => Priority.defaultPriority,
        },
        groupKey: canal.codigo,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: canal.codigo,
        threadIdentifier: canal.codigo,
        interruptionLevel: switch (canal.nivel) {
          NivelAviso.alto => InterruptionLevel.active,
          NivelAviso.medio => InterruptionLevel.active,
        },
      ),
    );
    await _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
      payload: carga,
    );
  }
}
