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
/// Tres disparadores, un mismo ciclo completo:
/// - `iniciar()` (apertura de la app), sin que quien lo llama espere el
///   resultado antes de `runApp` (invariante 1 de CLAUDE.md). Corre ANTES
///   de que exista sesión si el dispositivo no tenía token guardado — el
///   pull de catálogo de ese primer intento falla por falta de sesión, sin
///   que nada lo reintente después, por eso hace falta el disparador de
///   abajo.
/// - [sincronizarAhora] tras un login exitoso (HU-03): sin este segundo
///   disparo, un dispositivo que se loguea por primera vez se queda con
///   "Órdenes vigentes" vacío hasta el próximo reinicio de la app o un
///   vaivén real de conectividad, aunque el servidor ya tenga catálogo
///   (hallazgo del dueño en el dispositivo real, 14/9/2026).
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
/// reintentos, backoff ni temporizador propio. Un error de servidor (o una
/// respuesta mal formada) durante el loop de catálogo no debe impedir que
/// el outbox y las evidencias sincronicen igual en el mismo ciclo — ver
/// [_agotarCatalogo].
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

  /// Dispara un ciclo completo fuera de `iniciar()` y de una transición de
  /// conectividad — hoy solo lo llama la app tras un login exitoso (ver
  /// comentario de clase). A diferencia de `iniciar()`, no toca la
  /// suscripción a [cambiosConectividad]: llamarlo más de una vez nunca
  /// duplica esa suscripción.
  Future<void> sincronizarAhora() => _ciclo();

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
    await _agotarCatalogo();
    await _syncEngine.sincronizar();
    await _evidenciaSyncEngine.sincronizar();
  }

  /// Agota el pull de catálogo (loop hasta que no queda más). Deliberadamente
  /// silencioso ante cualquier error acá — mismo criterio que
  /// `ApiExcepcionRed` en `CatalogoRepository.pull()`: este disparador no
  /// tiene `Stream` de estado propio para reportarlo, y no hace falta uno
  /// nuevo porque el próximo disparo (conectividad, login, apertura de app)
  /// vuelve a intentar el catálogo desde el mismo cursor. Sin este `catch`,
  /// un error de servidor (401 del primer intento sin sesión, 500, una
  /// respuesta mal formada) cortaba acá TODO el ciclo — el outbox y las
  /// evidencias, que no dependen del catálogo, se quedaban sin sincronizar
  /// también (hallazgo de la revisión línea por línea del dueño, 14/9/2026).
  Future<void> _agotarCatalogo() async {
    try {
      var hayMasCatalogo = true;
      while (hayMasCatalogo) {
        hayMasCatalogo = await _catalogoRepositorio.pull();
      }
    } on Object {
      // Ver el porqué en el docstring de este método.
    }
  }
}
