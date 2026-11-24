import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/seguimiento_repositorio.dart';

enum FaseSeguimiento {
  /// Todavía no llegó el primer fotograma.
  cargando,

  /// Hay un fotograma y el seguimiento sigue vivo.
  enVivo,

  /// Hay un fotograma, pero el seguimiento se cortó: se muestra lo último
  /// conocido.
  sinSenal,

  /// No se pudo obtener ningún fotograma.
  error,
}

class SeguimientoEstado {
  const SeguimientoEstado({
    required this.fase,
    this.fotograma,
    this.sinConexion = false,
  });

  const SeguimientoEstado.cargando() : this(fase: FaseSeguimiento.cargando);

  final FaseSeguimiento fase;

  /// Último fotograma conocido.
  final SeguimientoVivo? fotograma;

  /// La falla fue por falta de red (y no por un error del servidor).
  final bool sinConexion;

  bool get terminado => fotograma?.estado == EstadoServicio.completado;
}

/// Seguimiento en vivo de un servicio. Lee el `Stream` del repositorio y
/// conserva el último fotograma cuando la señal se corta.
class SeguimientoCubit extends Cubit<SeguimientoEstado> {
  SeguimientoCubit(this._repositorio, this.servicioId)
    : super(const SeguimientoEstado.cargando()) {
    _escuchar();
  }

  final SeguimientoRepositorio _repositorio;
  final String servicioId;
  StreamSubscription<SeguimientoVivo>? _suscripcion;

  void _escuchar() {
    _suscripcion?.cancel();
    try {
      _suscripcion = _repositorio
          .observar(servicioId)
          .listen(
            (f) => emit(
              SeguimientoEstado(fase: FaseSeguimiento.enVivo, fotograma: f),
            ),
            onError: _alFallar,
          );
    } on Object catch (e) {
      _alFallar(e);
    }
  }

  void _alFallar(Object error) {
    if (isClosed) return;
    final previo = state.fotograma;
    emit(
      SeguimientoEstado(
        fase: previo == null ? FaseSeguimiento.error : FaseSeguimiento.sinSenal,
        fotograma: previo,
        sinConexion: error is SinConexion,
      ),
    );
  }

  /// Vuelve a suscribirse conservando el último fotograma.
  void reintentar() {
    if (state.fotograma == null) emit(const SeguimientoEstado.cargando());
    _escuchar();
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
