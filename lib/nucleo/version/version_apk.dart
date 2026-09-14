/// Una versión autorizada del APK de agrocom-field — espejo de `VersionApk`
/// en `docs/api/openapi.yaml` (HU-20, `GET /api/version`). Dart puro, sin
/// dependencias de Flutter.
class VersionApk {
  const VersionApk({
    required this.version,
    required this.versionCode,
    required this.urlDescarga,
  });

  /// SemVer, ej. `1.4.2`.
  final String version;

  /// Código de versión de Android (`versionCode`), ej. `14002`.
  final int versionCode;

  final String urlDescarga;

  factory VersionApk.fromJson(Map<String, dynamic> json) => VersionApk(
    version: json['version'] as String,
    versionCode: json['version_code'] as int,
    urlDescarga: json['url_descarga'] as String,
  );

  @override
  bool operator ==(Object other) =>
      other is VersionApk &&
      other.version == version &&
      other.versionCode == versionCode &&
      other.urlDescarga == urlDescarga;

  @override
  int get hashCode => Object.hash(version, versionCode, urlDescarga);
}
