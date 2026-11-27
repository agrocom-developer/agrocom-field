import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/cuenta_seguridad.dart';

enum EtapaEliminar {
  /// Leyendo el estado y los impedimentos.
  cargando,

  /// No se pudo leer; ver [EliminarCuentaEstado.falla].
  error,

  /// Con el estado a la vista: se puede pedir la eliminación o, si ya hay
  /// una en gracia, conservar la cuenta.
  listo,

  /// Esperando la respuesta del servidor.
  enviando,

  /// El servidor aceptó la eliminación: la sesión ya no vale.
  solicitada,

  /// «Conservar mi cuenta» funcionó: la cuenta vuelve a operar.
  conservada,
}

class EliminarCuentaEstado {
  const EliminarCuentaEstado({
    this.etapa = EtapaEliminar.cargando,
    this.consulta,
    this.eliminacion,
    this.falla,
  });

  final EtapaEliminar etapa;
  final ConsultaEliminacion? consulta;

  /// La solicitud aceptada (o la vigente, al conservar).
  final EliminacionCuenta? eliminacion;
  final CuentaFalla? falla;

  EliminarCuentaEstado copiarCon({
    EtapaEliminar? etapa,
    ConsultaEliminacion? consulta,
    EliminacionCuenta? eliminacion,
    CuentaFalla? Function()? falla,
  }) => EliminarCuentaEstado(
    etapa: etapa ?? this.etapa,
    consulta: consulta ?? this.consulta,
    eliminacion: eliminacion ?? this.eliminacion,
    falla: falla != null ? falla() : this.falla,
  );
}

/// «Eliminar mi cuenta» (ADR 0047) y el estado de una cuenta en eliminación.
/// La app explica los impedimentos y envía la confirmación; el servidor
/// decide y calcula los plazos.
class EliminarCuentaCubit extends Cubit<EliminarCuentaEstado> {
  EliminarCuentaCubit(this._repositorio) : super(const EliminarCuentaEstado());

  final CuentaSeguridadRepositorio _repositorio;

  Future<void> cargar() async {
    emit(const EliminarCuentaEstado());
    try {
      final consulta = await _repositorio.consultarEliminacion();
      if (isClosed) return;
      emit(
        EliminarCuentaEstado(etapa: EtapaEliminar.listo, consulta: consulta),
      );
    } on CuentaFalla catch (e) {
      if (!isClosed) {
        emit(EliminarCuentaEstado(etapa: EtapaEliminar.error, falla: e));
      }
    }
  }

  /// Confirma con la contraseña. Para confirmar con un código se usa un
  /// `FlujoCodigoCubit` y, al terminar, [registrarSolicitud].
  Future<void> eliminarConContrasena(String contrasena) async {
    if (state.etapa == EtapaEliminar.enviando) return;
    emit(state.copiarCon(etapa: EtapaEliminar.enviando, falla: () => null));
    try {
      final eliminacion = await _repositorio.eliminarCuenta(
        contrasena: contrasena,
      );
      if (isClosed) return;
      registrarSolicitud(eliminacion);
    } on CuentaEliminacionBloqueada catch (e) {
      if (isClosed) return;
      // Algo cambió desde la última lectura: se muestran los motivos nuevos.
      emit(
        state.copiarCon(
          etapa: EtapaEliminar.listo,
          consulta: ConsultaEliminacion(impedimentos: e.motivos),
          falla: () => e,
        ),
      );
    } on CuentaFalla catch (e) {
      if (!isClosed) {
        emit(state.copiarCon(etapa: EtapaEliminar.listo, falla: () => e));
      }
    }
  }

  /// El flujo del código confirmó la eliminación.
  void registrarSolicitud(EliminacionCuenta eliminacion) => emit(
    state.copiarCon(
      etapa: EtapaEliminar.solicitada,
      eliminacion: eliminacion,
      falla: () => null,
    ),
  );

  Future<void> conservar() async {
    if (state.etapa == EtapaEliminar.enviando) return;
    emit(state.copiarCon(etapa: EtapaEliminar.enviando, falla: () => null));
    try {
      final eliminacion = await _repositorio.conservarCuenta();
      if (isClosed) return;
      emit(
        state.copiarCon(
          etapa: EtapaEliminar.conservada,
          eliminacion: eliminacion,
        ),
      );
    } on CuentaFalla catch (e) {
      if (!isClosed) {
        emit(state.copiarCon(etapa: EtapaEliminar.listo, falla: () => e));
      }
    }
  }

  void limpiarFalla() {
    if (state.falla == null) return;
    emit(state.copiarCon(falla: () => null));
  }
}
