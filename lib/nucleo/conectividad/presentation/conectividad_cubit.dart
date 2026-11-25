import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/conectividad_servicio.dart';

/// Estado de la red para la UI. Arranca en [EstadoRed.conRed] (no se muestra
/// un aviso falso mientras llega la primera lectura) y sigue al servicio.
class ConectividadCubit extends Cubit<EstadoRed> {
  ConectividadCubit(this._servicio) : super(EstadoRed.conRed) {
    _suscripcion = _servicio.cambios.listen(emit);
    unawaited(_leerInicial());
  }

  final ConectividadServicio _servicio;
  late final StreamSubscription<EstadoRed> _suscripcion;
  bool _huboCambio = false;

  Future<void> _leerInicial() async {
    try {
      final estado = await _servicio.consultar();
      if (!isClosed && !_huboCambio) emit(estado);
    } catch (_) {
      // Sin lectura inicial se mantiene el supuesto "con red".
    }
  }

  @override
  void onChange(Change<EstadoRed> change) {
    super.onChange(change);
    _huboCambio = true;
  }

  @override
  Future<void> close() async {
    await _suscripcion.cancel();
    return super.close();
  }
}
