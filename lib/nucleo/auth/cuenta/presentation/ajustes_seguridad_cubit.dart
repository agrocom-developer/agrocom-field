import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/cuenta_seguridad.dart';

sealed class AjustesSeguridadEstado {
  const AjustesSeguridadEstado();
}

final class AjustesSeguridadCargando extends AjustesSeguridadEstado {
  const AjustesSeguridadCargando();
}

final class AjustesSeguridadError extends AjustesSeguridadEstado {
  const AjustesSeguridadError(this.falla);
  final CuentaFalla falla;
}

final class AjustesSeguridadListo extends AjustesSeguridadEstado {
  const AjustesSeguridadListo(this.perfil);
  final PerfilSeguridad perfil;
}

/// Lee si el teléfono de la cuenta ya está verificado. Es el único dato que
/// la pantalla de seguridad necesita del servidor.
class AjustesSeguridadCubit extends Cubit<AjustesSeguridadEstado> {
  AjustesSeguridadCubit(this._repositorio)
    : super(const AjustesSeguridadCargando());

  final CuentaSeguridadRepositorio _repositorio;

  Future<void> cargar() async {
    // Con datos a la vista, releer no vuelve a la carga.
    if (state is! AjustesSeguridadListo) {
      emit(const AjustesSeguridadCargando());
    }
    try {
      final perfil = await _repositorio.perfil();
      if (!isClosed) emit(AjustesSeguridadListo(perfil));
    } on CuentaFalla catch (e) {
      if (!isClosed && state is! AjustesSeguridadListo) {
        emit(AjustesSeguridadError(e));
      }
    }
  }
}
