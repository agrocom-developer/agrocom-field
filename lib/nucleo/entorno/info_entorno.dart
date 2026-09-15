import '../flavor.dart';

/// Lo que la app sabe de sí misma para mostrárselo a quien la opera —
/// flavor instalado, contra qué servidor apunta y qué versión es —, resuelto
/// una vez al arrancar (`main_*.dart`) y pasado a las pantallas que lo
/// exponen (el pie del login, vía `PieEntornoCampo`).
///
/// Existe para que un APK apuntado al entorno equivocado se note antes de
/// cargar trabajo real (ADR 0004: la URL base la inyecta el build, y por
/// afuera dos APK son indistinguibles) y para que soporte sepa qué versión
/// tiene el piloto en la mano sin mandarlo a Ajustes (ADR 0007).
class InfoEntorno {
  const InfoEntorno({
    required this.flavor,
    required this.hostApi,
    required this.version,
  });

  final Flavor flavor;

  /// Host (y puerto, si no es el del esquema) de `API_BASE_URL` — p. ej.
  /// `192.168.0.3:8000` o `api.agrocom.com.ar`. Alcanza para reconocer el
  /// entorno sin ensuciar el pie con esquema ni ruta.
  final String hostApi;

  /// `versionName+versionCode` tal como los reporta la plataforma (p. ej.
  /// `0.1.0+1`) — el mismo formato que `pubspec.yaml` y que el tag de
  /// release (ADR 0007), para que soporte y el piloto hablen del mismo
  /// número.
  final String version;

  /// Reduce una URL base a su host (más el puerto explícito, si lo hay). Si
  /// el texto no parsea como URL con host, se devuelve tal cual: mejor ver
  /// algo raro al pie que esconder contra qué apunta el APK.
  static String hostDe(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.host.isEmpty) return apiBaseUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
}
