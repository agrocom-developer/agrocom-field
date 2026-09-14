import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../catalogo/catalogo_repository.dart';
import '../evidencias/evidencia_sync_engine.dart';
import 'sync_engine.dart';

/// Disparador único de sincronización (TE-19) — el punto de la app que
/// conecta [CatalogoRepository.pull], [SyncEngine.sincronizar] y
/// [EvidenciaSyncEngine.sincronizar] con un evento real. Sin esto, los tres
/// motores existen, están probados y registrados en el DI, pero nada los
/// invoca en producción (ver hallazgo en `docs/gestion/cola_tareas.md`).
///
/// Vive en `nucleo/`, sin BLoC ni `Stream` de estado propio (mismo criterio
/// que `VersionWatcher`/`AvisosLocalesWatcher`): se instancia una sola vez
/// en `main_piloto.dart`/`main_auxiliar.dart` y vive tanto como la app.
///
/// Dos disparadores, un mismo ciclo completo:
/// - `iniciar()` (apertura de la app), sin que quien lo llama espere el
///   resultado antes de `runApp` (invariante 1 de CLAUDE.md).
/// - la transición sin-conectividad → con-conectividad en
///   [cambiosConectividad] (`Connectivity().onConnectivityChanged`). Otras
///   transiciones (con-señal → sin-señal, o entre tipos de conexión) no
///   disparan un ciclo nuevo — mismo criterio que la primera emisión
///   descartada como línea de base en `AvisosLocalesWatcher`.
///
/// Un ciclo completo agota el catálogo (loop de `pull()` hasta que no
/// queda más), después empuja el outbox, después sube evidencias — los
/// tres son independientes entre sí (no comparten transacción), y cada uno
/// ya resuelve su propia falta de señal sin que este disparador agregue
/// reintentos, backoff ni temporizador propio.
class DisparadorSync {
  DisparadorSync({
    required CatalogoRepository catalogoRepositorio,
    required SyncEngine syncEngine,
    required EvidenciaSyncEngine evidenciaSyncEngine,
    required Stream<List<ConnectivityResult>> cambiosConectividad,
  }) : _catalogoRepositorio = catalogoRepositorio,
       _syncEngine = syncEngine,
       _evidenciaSyncEngine = evidenciaSyncEngine,
       _cambiosConectividad = cambiosConectividad;

  final CatalogoRepository _catalogoRepositorio;
  final SyncEngine _syncEngine;
  final EvidenciaSyncEngine _evidenciaSyncEngine;
  final Stream<List<ConnectivityResult>> _cambiosConectividad;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  bool _primeraEmision = true;
  bool _teniaConectividad = false;

  Future<void> iniciar() async {
    _primeraEmision = true;
    _suscripcion = _cambiosConectividad.listen(_procesarConectividad);
    await _ciclo();
  }

  Future<void> detener() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
  }

  void _procesarConectividad(List<ConnectivityResult> resultados) {
    final hayConectividad = _hayConectividad(resultados);

    // La primera emisión solo establece la línea de base: `iniciar()` ya
    // disparó su propio ciclo, así que reportar la conectividad actual acá
    // no debe contar como una transición sin-señal → con-señal.
    if (_primeraEmision) {
      _primeraEmision = false;
      _teniaConectividad = hayConectividad;
      return;
    }

    if (hayConectividad && !_teniaConectividad) {
      unawaited(_ciclo());
    }
    _teniaConectividad = hayConectividad;
  }

  bool _hayConectividad(List<ConnectivityResult> resultados) =>
      resultados.any((resultado) => resultado != ConnectivityResult.none);

  Future<void> _ciclo() async {
    var hayMasCatalogo = true;
    while (hayMasCatalogo) {
      hayMasCatalogo = await _catalogoRepositorio.pull();
    }
    await _syncEngine.sincronizar();
    await _evidenciaSyncEngine.sincronizar();
  }
}
