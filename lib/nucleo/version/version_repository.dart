import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import 'estado_version.dart';
import 'version_apk.dart';

/// Consulta `GET /api/version` (HU-20) y decide si el `version_code`
/// instalado queda bloqueado contra la mínima autorizada por el dueño.
///
/// Sin autenticación a propósito: `ApiClient` ya tolera llamar sin token
/// (`AuthInterceptor` solo agrega el header `Authorization` si hay uno
/// guardado), así que no hace falta un cliente aparte para este endpoint
/// público.
class VersionRepository {
  VersionRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Cualquier falla al consultar — de red o del servidor — devuelve
  /// [VersionPermitida]: solo una respuesta exitosa puede bloquear la app
  /// (invariante 1 de CLAUDE.md, la app nunca depende de que la red
  /// responda).
  Future<EstadoVersion> consultarEstado(int versionCodeInstalado) async {
    final VersionApk? minima;
    try {
      final respuesta = await _apiClient.get('/api/version');
      final cuerpo = respuesta.data as Map<String, dynamic>;
      final minimaJson = cuerpo['minima'];
      minima = minimaJson == null
          ? null
          : VersionApk.fromJson(minimaJson as Map<String, dynamic>);
    } on ApiExcepcion {
      return const VersionPermitida();
    }
    return evaluarEstadoVersion(
      minima: minima,
      versionCodeInstalado: versionCodeInstalado,
    );
  }
}
