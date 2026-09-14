import 'dart:async';

import 'estado_version.dart';
import 'version_instalada.dart';
import 'version_repository.dart';

/// Repite la consulta de HU-20 mientras la app está en primer plano — sin
/// FCM, por polling (ver `especificacion_funcional_tecnica.md` §... de
/// `agrocom-api`, "control de actualizaciones por red"). Vive en `nucleo/`,
/// sin BLoC: publica su estado por [estado], mismo criterio que
/// `SyncEngine` sobre `SyncCubit`.
///
/// El `version_code` instalado no cambia mientras el proceso vive (no hay
/// auto-actualización en caliente), así que se lee una sola vez en
/// [iniciar] y se reutiliza en cada ciclo — no hace falta volver a
/// preguntarle a la plataforma en cada poll.
class VersionWatcher {
  VersionWatcher({
    required VersionRepository repositorio,
    required VersionInstalada versionInstalada,
    this.intervalo = const Duration(minutes: 15),
  }) : _repositorio = repositorio,
       _versionInstalada = versionInstalada;

  final VersionRepository _repositorio;
  final VersionInstalada _versionInstalada;
  final Duration intervalo;

  final _controladorEstado = StreamController<EstadoVersion>.broadcast();
  Timer? _timer;
  int? _versionCodeInstalado;

  Stream<EstadoVersion> get estado => _controladorEstado.stream;

  Future<void> iniciar() async {
    _versionCodeInstalado = await _versionInstalada.versionCode();
    await _consultar();
    _timer = Timer.periodic(intervalo, (_) => _consultar());
  }

  Future<void> _consultar() async {
    final estado = await _repositorio.consultarEstado(_versionCodeInstalado!);
    _controladorEstado.add(estado);
  }

  void detener() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    detener();
    _controladorEstado.close();
  }
}
