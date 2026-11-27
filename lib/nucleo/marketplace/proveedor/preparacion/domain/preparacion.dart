/// Lo que el piloto revisa antes de salir al lote. Es una guía propia: no la
/// pide el servidor y no bloquea ofertar ni iniciar un servicio.
enum ItemPreparacion {
  baterias,
  tanque,
  boquillas,
  mandoRc,
  dron,
  epp,
  documentos,
  clima,
  pronostico,
}

/// La lista de preparación del equipo con lo que ya se marcó.
class ChecklistPreparacion {
  const ChecklistPreparacion([this.hechos = const {}]);

  final Set<ItemPreparacion> hechos;

  int get total => ItemPreparacion.values.length;
  int get completados => hechos.length;
  double get progreso => total == 0 ? 0 : completados / total;
  bool get completo => completados == total;

  bool estaHecho(ItemPreparacion item) => hechos.contains(item);

  ChecklistPreparacion alternar(ItemPreparacion item) => ChecklistPreparacion(
    estaHecho(item) ? ({...hechos}..remove(item)) : {...hechos, item},
  );

  List<String> aJson() => [for (final i in hechos) i.name];

  static ChecklistPreparacion deJson(Iterable<Object?> nombres) {
    final porNombre = ItemPreparacion.values.asNameMap();
    return ChecklistPreparacion({for (final n in nombres) ?porNombre['$n']});
  }
}

/// Dónde se guarda la lista en este teléfono. Sin [servicioId] es la lista
/// genérica del piloto; con él, la de ese servicio. No usa la red ni el
/// outbox: es una guía personal, no un registro del lote.
abstract interface class PreparacionStore {
  Future<ChecklistPreparacion> leer({int? servicioId});

  Future<void> guardar(ChecklistPreparacion lista, {int? servicioId});
}

class PreparacionMemoria implements PreparacionStore {
  final _listas = <int?, ChecklistPreparacion>{};

  @override
  Future<ChecklistPreparacion> leer({int? servicioId}) async =>
      _listas[servicioId] ?? const ChecklistPreparacion();

  @override
  Future<void> guardar(ChecklistPreparacion lista, {int? servicioId}) async =>
      _listas[servicioId] = lista;
}
