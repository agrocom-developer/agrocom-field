import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dominio/falla.dart';
import '../domain/cuenta_proveedor.dart';

sealed class EstadoCuentaEstado {
  const EstadoCuentaEstado();
}

final class EstadoCuentaCargando extends EstadoCuentaEstado {
  const EstadoCuentaCargando();
}

final class EstadoCuentaError extends EstadoCuentaEstado {
  const EstadoCuentaError({this.mensaje, this.sinRed = false});

  final String? mensaje;
  final bool sinRed;
}

final class EstadoCuentaListo extends EstadoCuentaEstado {
  const EstadoCuentaListo(
    this.cuenta, {
    this.reenviando = false,
    this.aviso,
    this.actualizando = false,
  });

  final EstadoCuentaProveedor cuenta;
  final bool reenviando;
  final bool actualizando;

  /// Mensaje del último intento de reenviar, si falló.
  final String? aviso;

  EstadoCuentaListo copiarCon({
    EstadoCuentaProveedor? cuenta,
    bool? reenviando,
    bool? actualizando,
    String? Function()? aviso,
  }) => EstadoCuentaListo(
    cuenta ?? this.cuenta,
    reenviando: reenviando ?? this.reenviando,
    actualizando: actualizando ?? this.actualizando,
    aviso: aviso != null ? aviso() : this.aviso,
  );
}

/// Lee el estado de la cuenta del proveedor. La app muestra y el servidor
/// decide: se vuelve a leer al abrir, al volver de segundo plano y tras subir
/// documentos (ADR 0024, punto 4).
class EstadoCuentaCubit extends Cubit<EstadoCuentaEstado> {
  EstadoCuentaCubit(this._repositorio) : super(const EstadoCuentaCargando());

  final CuentaProveedorRepositorio _repositorio;

  Future<void> cargar() async {
    emit(const EstadoCuentaCargando());
    await _leer();
  }

  /// Relectura silenciosa: no vuelve a mostrar la carga si ya hay datos.
  Future<void> actualizar() async {
    final actual = state;
    if (actual is EstadoCuentaListo) {
      emit(actual.copiarCon(actualizando: true));
    }
    await _leer();
  }

  Future<void> _leer() async {
    try {
      final cuenta = await _repositorio.estado();
      if (!isClosed) emit(EstadoCuentaListo(cuenta));
    } on SinConexion {
      _fallo(const EstadoCuentaError(sinRed: true));
    } on OperacionRechazada catch (e) {
      _fallo(EstadoCuentaError(mensaje: e.mensaje));
    }
  }

  /// Con datos ya mostrados, un fallo de relectura no los borra.
  void _fallo(EstadoCuentaError error) {
    if (isClosed) return;
    final actual = state;
    if (actual is EstadoCuentaListo) {
      emit(actual.copiarCon(actualizando: false));
    } else {
      emit(error);
    }
  }

  Future<void> reenviar({required String mensajeSinRed}) async {
    final actual = state;
    if (actual is! EstadoCuentaListo || actual.reenviando) return;
    emit(actual.copiarCon(reenviando: true, aviso: () => null));
    try {
      await _repositorio.reenviarARevision();
      await _leer();
    } on SinConexion {
      if (!isClosed) {
        emit(actual.copiarCon(reenviando: false, aviso: () => mensajeSinRed));
      }
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(actual.copiarCon(reenviando: false, aviso: () => e.mensaje));
      }
    }
  }
}
