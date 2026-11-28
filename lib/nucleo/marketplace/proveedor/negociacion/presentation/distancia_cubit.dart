import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dominio/geo.dart';
import '../../ejecucion/domain/ejecucion.dart';
import '../domain/distancia_al_lote.dart';

enum FaseDistancia {
  /// Todavía no se pidió: se ofrece calcularla.
  inicial,

  /// Se pidió el permiso o se lee la posición.
  calculando,
  lista,
  sinPermiso,
  denegadoParaSiempre,
  servicioApagado,
  sinPosicion,
  sinLote,
}

class DistanciaEstado {
  const DistanciaEstado({this.fase = FaseDistancia.inicial, this.km});

  final FaseDistancia fase;

  /// El único dato que se conserva: la distancia, nunca la posición.
  final Decimal? km;
}

/// Calcula la distancia del piloto al lote con la posición actual. La
/// posición se lee una sola vez por cálculo y se descarta: no se guarda en
/// `drift`, no se registra y no se envía a ninguna parte. El permiso se pide
/// recién cuando la persona toca «Ver distancia», con su explicación.
class DistanciaCubit extends Cubit<DistanciaEstado> {
  DistanciaCubit(this._servicio) : super(const DistanciaEstado());

  final ServicioUbicacion _servicio;

  /// [explicar] muestra el motivo y devuelve si la persona continúa.
  Future<void> calcular(
    GeoPunto? lote, {
    required Future<bool> Function() explicar,
  }) async {
    if (lote == null) {
      emit(const DistanciaEstado(fase: FaseDistancia.sinLote));
      return;
    }
    if (state.fase == FaseDistancia.calculando) return;
    emit(DistanciaEstado(fase: FaseDistancia.calculando, km: state.km));
    var permiso = await _servicio.estado();
    if (isClosed) return;
    switch (permiso) {
      case PermisoUbicacion.servicioApagado:
        emit(const DistanciaEstado(fase: FaseDistancia.servicioApagado));
        return;
      case PermisoUbicacion.denegadoParaSiempre:
        emit(const DistanciaEstado(fase: FaseDistancia.denegadoParaSiempre));
        return;
      case PermisoUbicacion.denegado:
        if (!await explicar()) {
          if (!isClosed) {
            emit(DistanciaEstado(fase: FaseDistancia.inicial, km: state.km));
          }
          return;
        }
        permiso = await _servicio.pedir();
        if (isClosed) return;
        if (permiso == PermisoUbicacion.denegadoParaSiempre) {
          emit(const DistanciaEstado(fase: FaseDistancia.denegadoParaSiempre));
          return;
        }
        if (permiso == PermisoUbicacion.servicioApagado) {
          emit(const DistanciaEstado(fase: FaseDistancia.servicioApagado));
          return;
        }
        if (permiso != PermisoUbicacion.concedido) {
          emit(const DistanciaEstado(fase: FaseDistancia.sinPermiso));
          return;
        }
      case PermisoUbicacion.concedido:
        break;
    }
    final posicion = await _servicio.actual();
    if (isClosed) return;
    if (posicion == null) {
      emit(const DistanciaEstado(fase: FaseDistancia.sinPosicion));
      return;
    }
    emit(
      DistanciaEstado(
        fase: FaseDistancia.lista,
        km: DistanciaAlLote.kilometros(posicion, lote),
      ),
    );
  }
}
