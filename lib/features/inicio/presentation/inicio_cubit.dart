import 'dart:async';

import 'package:bloc/bloc.dart';

import '../data/inicio_repository.dart';
import '../domain/trabajo_asignado.dart';
import 'inicio_estado.dart';

/// Adaptador delgado entre `InicioRepository` y la pantalla «Inicio» —
/// mismo criterio que `OrdenesCubit`: se suscribe al `Stream` local al
/// construirse y traduce cada emisión a un `InicioEstado`.
class InicioCubit extends Cubit<InicioEstado> {
  InicioCubit(InicioRepository repositorio) : super(const InicioCargando()) {
    _suscripcion = repositorio.trabajoAsignado().listen(_alRecibir);
  }

  late final StreamSubscription<TrabajoAsignado?> _suscripcion;

  void _alRecibir(TrabajoAsignado? trabajo) {
    emit(
      trabajo == null ? const InicioSinTrabajo() : InicioConTrabajo(trabajo),
    );
  }

  @override
  Future<void> close() async {
    await _suscripcion.cancel();
    return super.close();
  }
}
