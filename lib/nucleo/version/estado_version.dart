import 'version_apk.dart';

/// Resultado de comparar el `version_code` instalado contra la versión
/// mínima autorizada (HU-20). El único criterio de bloqueo es `minima` —
/// nunca `vigente`, que es puramente informativo (ver CLAUDE.md de la
/// tarea).
sealed class EstadoVersion {
  const EstadoVersion();
}

/// Cubre tanto "el dueño no fijó mínima todavía" como "la instalada la
/// cumple" — ambos casos habilitan el uso normal de la app.
final class VersionPermitida extends EstadoVersion {
  const VersionPermitida();
}

/// `version_code` instalado por debajo de [minima] — bloquea el uso hasta
/// actualizar.
final class VersionBloqueada extends EstadoVersion {
  const VersionBloqueada(this.minima);

  final VersionApk minima;

  @override
  bool operator ==(Object other) =>
      other is VersionBloqueada && other.minima == minima;

  @override
  int get hashCode => minima.hashCode;
}

EstadoVersion evaluarEstadoVersion({
  required VersionApk? minima,
  required int versionCodeInstalado,
}) {
  if (minima != null && versionCodeInstalado < minima.versionCode) {
    return VersionBloqueada(minima);
  }
  return const VersionPermitida();
}
