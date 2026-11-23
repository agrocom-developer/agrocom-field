import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dominio/dominio.dart';
import '../domain/drones_repositorio.dart';

sealed class DronesEstado {
  const DronesEstado();
}

final class DronesCargando extends DronesEstado {
  const DronesCargando();
}

final class DronesError extends DronesEstado {
  const DronesError();
}

final class DronesListos extends DronesEstado {
  const DronesListos(this.drones);

  /// Primero los que piden atención (batería por agotarse, mantenimiento,
  /// sin aprobar), después el resto.
  final List<Dron> drones;
}

/// Los drones del proveedor: los «vehículos» del marketplace.
class DronesCubit extends Cubit<DronesEstado> {
  DronesCubit(this._repositorio) : super(const DronesCargando());

  final DronesRepositorio _repositorio;
  StreamSubscription<List<Dron>>? _sub;

  void iniciar() {
    if (state is! DronesCargando) emit(const DronesCargando());
    _sub?.cancel();
    _sub = _repositorio.observar().listen(
      (drones) => emit(DronesListos(_ordenar(drones))),
      onError: (Object _) {
        if (!isClosed) emit(const DronesError());
      },
    );
  }

  static int _urgencia(Dron d) {
    if (!d.aprobacion.habilitado) return 0;
    if (d.bateriaPorAgotarse) return 1;
    if (d.estado == EstadoDron.mantenimiento) return 2;
    return 3;
  }

  static List<Dron> _ordenar(List<Dron> drones) {
    final indices = {for (var i = 0; i < drones.length; i++) drones[i]: i};
    return [...drones]..sort((a, b) {
      final porUrgencia = _urgencia(a).compareTo(_urgencia(b));
      return porUrgencia != 0 ? porUrgencia : indices[a]! - indices[b]!;
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
