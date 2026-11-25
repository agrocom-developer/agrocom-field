import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/conectividad_servicio.dart';

/// Implementación sobre `connectivity_plus`. Que haya interfaz de red no
/// garantiza llegar al servidor; es el mismo criterio del disparador de sync.
class ConectividadReal implements ConectividadServicio {
  ConectividadReal({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static EstadoRed _estado(List<ConnectivityResult> r) =>
      r.isEmpty || r.contains(ConnectivityResult.none)
      ? EstadoRed.sinRed
      : EstadoRed.conRed;

  @override
  Future<EstadoRed> consultar() async =>
      _estado(await _connectivity.checkConnectivity());

  @override
  Stream<EstadoRed> get cambios =>
      _connectivity.onConnectivityChanged.map(_estado).distinct();
}
