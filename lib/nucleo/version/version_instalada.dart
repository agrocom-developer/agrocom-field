import 'package:package_info_plus/package_info_plus.dart';

/// Lee el `version_code` de Android de la build instalada — abstracta para
/// poder fakear en tests sin canal de plataforma real, mismo patrón que
/// `nucleo/linterna/linterna_controlador.dart`.
abstract class VersionInstalada {
  Future<int> versionCode();
}

/// Envuelve el plugin `package_info_plus`. `buildNumber` llega como String
/// (es el `versionCode` de Android tal cual lo reporta la plataforma) — se
/// parsea a `int` para poder compararlo con la mínima del servidor.
class VersionInstaladaPackageInfo implements VersionInstalada {
  @override
  Future<int> versionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.parse(info.buildNumber);
  }
}
