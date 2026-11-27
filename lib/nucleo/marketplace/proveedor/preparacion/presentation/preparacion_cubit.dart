import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/preparacion.dart';

class PreparacionEstado {
  const PreparacionEstado({
    this.cargando = true,
    this.lista = const ChecklistPreparacion(),
    this.noSeGuardo = false,
  });

  final bool cargando;
  final ChecklistPreparacion lista;

  /// El último cambio no se pudo guardar en el teléfono; se sigue viendo.
  final bool noSeGuardo;
}

/// Marca y desmarca los pasos de la preparación y guarda cada cambio al
/// momento. Nada espera a la red.
class PreparacionCubit extends Cubit<PreparacionEstado> {
  PreparacionCubit(this._store, {this.servicioId})
    : super(const PreparacionEstado());

  final PreparacionStore _store;

  /// Con un servicio, la lista es la de ese servicio; sin él, la genérica.
  final int? servicioId;

  Future<void> cargar() async {
    try {
      final lista = await _store.leer(servicioId: servicioId);
      if (!isClosed) emit(PreparacionEstado(cargando: false, lista: lista));
    } on Object {
      // Sin lectura se empieza con la lista vacía: es una guía, no un dato.
      if (!isClosed) emit(const PreparacionEstado(cargando: false));
    }
  }

  Future<void> alternar(ItemPreparacion item) =>
      _cambiar(state.lista.alternar(item));

  Future<void> reiniciar() => _cambiar(const ChecklistPreparacion());

  Future<void> _cambiar(ChecklistPreparacion nueva) async {
    emit(PreparacionEstado(cargando: false, lista: nueva));
    try {
      await _store.guardar(nueva, servicioId: servicioId);
    } on Object {
      if (!isClosed) {
        emit(
          PreparacionEstado(cargando: false, lista: nueva, noSeGuardo: true),
        );
      }
    }
  }
}
