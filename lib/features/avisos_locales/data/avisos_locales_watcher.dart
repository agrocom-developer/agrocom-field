import 'dart:async';

import '../../../nucleo/notificaciones/notificador_local.dart';
import '../../ordenes/data/ordenes_repository.dart';
import '../../ordenes/domain/orden_vigente.dart';
import '../domain/reglas_avisos.dart';
import 'ids_vistos_store.dart';

/// Vigila el mismo `Stream<List<OrdenVigente>>` de `OrdenesRepository` que
/// consume `OrdenesCubit` (invariante 1 de CLAUDE.md: la UI y este watcher
/// leen del mismo repositorio local, nunca de la red directo) y dispara
/// una notificación por cada orden nueva.
///
/// La primera emisión de cada [iniciar] se descarta como línea de base —
/// no avisa de todo lo que ya estaba al arrancar la app — y de ahí en
/// adelante solo avisa de los ids que no estaban en la última línea de
/// base conocida (cargada de [IdsVistosStore] al arrancar).
///
/// Vive tanto como la app: se instancia una sola vez en
/// `main_auxiliar.dart`, después de `configurarDependencias`. No es una
/// pieza que la UI cree ni destruya por pantalla.
class AvisosLocalesWatcher {
  AvisosLocalesWatcher({
    required OrdenesRepository ordenesRepositorio,
    required NotificadorLocal notificador,
    required IdsVistosStore idsVistosStore,
  }) : _ordenesRepositorio = ordenesRepositorio,
       _notificador = notificador,
       _idsVistosStore = idsVistosStore;

  final OrdenesRepository _ordenesRepositorio;
  final NotificadorLocal _notificador;
  final IdsVistosStore _idsVistosStore;

  Set<int> _idsVistos = {};
  bool _primeraEmision = true;
  StreamSubscription<List<OrdenVigente>>? _suscripcion;

  Future<void> iniciar() async {
    _idsVistos = await _idsVistosStore.leerVistos();
    _primeraEmision = true;
    _suscripcion = _ordenesRepositorio.ordenesVigentes().listen(_procesar);
  }

  Future<void> detener() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
  }

  Future<void> _procesar(List<OrdenVigente> actuales) async {
    if (_primeraEmision) {
      _primeraEmision = false;
      await _marcarVistas(actuales);
      return;
    }

    final nuevas = ordenesNuevas(
      actuales: actuales,
      idsYaNotificados: _idsVistos,
    );
    for (final orden in nuevas) {
      await _notificador.mostrar(
        id: orden.id,
        titulo: 'Nueva orden sincronizada',
        cuerpo:
            'Orden #${orden.nroAplicacion} — lote ${orden.loteCodigo ?? orden.loteId}',
      );
    }
    await _marcarVistas(actuales);
  }

  Future<void> _marcarVistas(List<OrdenVigente> ordenes) async {
    _idsVistos = {..._idsVistos, ...ordenes.map((orden) => orden.id)};
    await _idsVistosStore.guardarVistos(_idsVistos);
  }
}
