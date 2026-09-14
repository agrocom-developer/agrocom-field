import 'dart:async';

import 'package:bloc/bloc.dart';

import '../data/ordenes_repository.dart';
import '../domain/orden_vigente.dart';
import 'ordenes_estado.dart';

/// Adaptador delgado entre `OrdenesRepository` (sin BLoC) y la pantalla de
/// lista — mismo criterio que `SyncCubit` sobre `SyncEngine`: se suscribe
/// al `Stream` del repositorio al construirse y traduce cada emisión a un
/// `OrdenesEstado`.
class OrdenesCubit extends Cubit<OrdenesEstado> {
  OrdenesCubit(OrdenesRepository repositorio) : super(const OrdenesCargando()) {
    _suscripcion = repositorio.ordenesVigentes().listen(_alRecibir);
  }

  late final StreamSubscription<List<OrdenVigente>> _suscripcion;

  void _alRecibir(List<OrdenVigente> ordenes) {
    emit(ordenes.isEmpty ? const OrdenesVacia() : OrdenesLista(ordenes));
  }

  @override
  Future<void> close() async {
    await _suscripcion.cancel();
    return super.close();
  }
}
