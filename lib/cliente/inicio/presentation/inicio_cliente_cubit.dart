import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/inicio_cliente_repositorio.dart';

sealed class InicioClienteEstado {
  const InicioClienteEstado();
}

final class InicioClienteCargando extends InicioClienteEstado {
  const InicioClienteCargando();
}

final class InicioClienteListo extends InicioClienteEstado {
  const InicioClienteListo(this.resumen);

  final ResumenInicio resumen;
}

final class InicioClienteFallido extends InicioClienteEstado {
  const InicioClienteFallido({required this.sinConexion});

  final bool sinConexion;
}

/// Inicio del cliente: escucha el resumen del repositorio y lo expone con
/// sus estados de carga y error. Vive mientras dure la navegación principal,
/// así cambiar de pestaña no vuelve a cargar.
class InicioClienteCubit extends Cubit<InicioClienteEstado> {
  InicioClienteCubit(this._repositorio) : super(const InicioClienteCargando());

  final InicioClienteRepositorio _repositorio;
  StreamSubscription<ResumenInicio>? _suscripcion;
  final _descartados = <String>{};

  void cargar() {
    _suscripcion?.cancel();
    emit(const InicioClienteCargando());
    _suscribir();
  }

  /// Vuelve a pedir el resumen sin pasar por el esqueleto (deslizar para
  /// actualizar). Termina cuando llega el primer dato o el error.
  Future<void> actualizar() async {
    await _suscripcion?.cancel();
    final listo = Completer<void>();
    _suscribir(alPrimerEvento: listo.complete);
    return listo.future;
  }

  void _suscribir({void Function()? alPrimerEvento}) {
    var primero = alPrimerEvento;
    void avisar() {
      primero?.call();
      primero = null;
    }

    _suscripcion = _repositorio.observar().listen(
      (resumen) {
        emit(InicioClienteListo(_filtrar(resumen)));
        avisar();
      },
      onError: (Object error) {
        emit(InicioClienteFallido(sinConexion: error is InicioSinConexion));
        avisar();
      },
      onDone: avisar,
    );
  }

  ResumenInicio _filtrar(ResumenInicio resumen) {
    var r = resumen;
    for (final id in _descartados) {
      r = r.sinAviso(id);
    }
    return r;
  }

  /// Quita un aviso de la vista. No se guarda: vuelve en la próxima sesión
  /// si sigue vigente.
  void descartarAviso(String id) {
    _descartados.add(id);
    final actual = state;
    if (actual is InicioClienteListo) {
      emit(InicioClienteListo(actual.resumen.sinAviso(id)));
    }
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
