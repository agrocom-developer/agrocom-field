import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificaciones locales generadas por reglas que corren en el dispositivo
/// (HU-62) — sin servidor push ni FCM. Abstracta para poder fakear en tests
/// sin canal de plataforma real, mismo patrón que `nucleo/auth`.
abstract class NotificadorLocal {
  /// Pide el permiso de notificaciones al sistema operativo (Android 13+,
  /// `POST_NOTIFICATIONS` en runtime). Devuelve si quedó concedido.
  Future<bool> pedirPermiso();

  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
  });
}

/// Envuelve `FlutterLocalNotificationsPlugin` — solo Android (los dos
/// flavors de este repo corren únicamente ahí, ver `docs/vision.md`).
class NotificadorLocalPlugin implements NotificadorLocal {
  NotificadorLocalPlugin([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _canalId = 'avisos_locales';
  static const _canalNombre = 'Avisos';
  static const _canalDescripcion =
      'Avisos generados en el dispositivo, sin conexión';

  bool _inicializado = false;

  Future<void> _asegurarInicializado() async {
    if (_inicializado) return;
    const configuracion = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
  }) async {
    await _asegurarInicializado();
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNombre,
        channelDescription: _canalDescripcion,
      ),
    );
    await _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
    );
  }
}
