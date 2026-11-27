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
    this.pendientesPorSubir = 0,
    this.sincronizando = false,
  });

  /// Registros del lote sin subir (solo piloto): mientras haya, no se ofrece
  /// eliminar.
  final int pendientesPorSubir;
  final bool sincronizando;

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
    int? pendientesPorSubir,
    bool? sincronizando,
  }) => EliminarCuentaEstado(
    etapa: etapa ?? this.etapa,
    consulta: consulta ?? this.consulta,
    eliminacion: eliminacion ?? this.eliminacion,
    falla: falla != null ? falla() : this.falla,
    pendientesPorSubir: pendientesPorSubir ?? this.pendientesPorSubir,
    sincronizando: sincronizando ?? this.sincronizando,
  );
}

/// «Eliminar mi cuenta» (ADR 0047) y el estado de una cuenta en eliminación.
/// La app explica los impedimentos y envía la confirmación; el servidor
/// decide y calcula los plazos.
class EliminarCuentaCubit extends Cubit<EliminarCuentaEstado> {
  EliminarCuentaCubit(
    this._repositorio, {
    PendientesDeSincronizacion? pendientes,
  }) : _pendientes = pendientes,
       super(const EliminarCuentaEstado());

  final CuentaSeguridadRepositorio _repositorio;
  final PendientesDeSincronizacion? _pendientes;

  Future<void> cargar() async {
    emit(const EliminarCuentaEstado());
    try {
      final consulta = await _repositorio.consultarEliminacion();
      final pendientes = await _contarPendientes();
      if (isClosed) return;
      emit(
        EliminarCuentaEstado(
          etapa: EtapaEliminar.listo,
          consulta: consulta,
          pendientesPorSubir: pendientes,
        ),
      );
    } on CuentaFalla catch (e) {
      if (!isClosed) {
        emit(EliminarCuentaEstado(etapa: EtapaEliminar.error, falla: e));
      }
    }
  }

  Future<int> _contarPendientes() async {
    try {
      return await _pendientes?.cantidad() ?? 0;
    } on Object {
      // Si no se puede contar, no se bloquea: el servidor decide.
      return 0;
    }
  }

  /// «Sincronizar ahora»: sube lo pendiente y vuelve a contar.
  Future<void> sincronizar() async {
    final pendientes = _pendientes;
    if (pendientes == null || state.sincronizando) return;
    emit(state.copiarCon(sincronizando: true));
    try {
      await pendientes.sincronizar();
    } on Object {
      // Sin red no se sube; el conteo de abajo lo refleja.
    }
    final quedan = await _contarPendientes();
    if (!isClosed) {
      emit(state.copiarCon(sincronizando: false, pendientesPorSubir: quedan));
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
