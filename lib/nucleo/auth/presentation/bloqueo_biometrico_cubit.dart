import 'package:flutter_bloc/flutter_bloc.dart';

import '../biometria.dart';
import '../bloqueo_biometrico.dart';

enum EtapaBloqueoAjuste {
  cargando,

  /// Se puede activar o desactivar.
  listo,

  /// Falta registrar huella o rostro en el teléfono.
  sinRegistrar,

  /// El teléfono no tiene lector.
  sinHardware,
}

class BloqueoBiometricoEstado {
  const BloqueoBiometricoEstado({
    this.etapa = EtapaBloqueoAjuste.cargando,
    this.activo = false,
    this.trabajando = false,
    this.noConfirmado = false,
  });

  final EtapaBloqueoAjuste etapa;
  final bool activo;
  final bool trabajando;

  /// El último intento de activar no se pudo confirmar con la biometría.
  final bool noConfirmado;

  BloqueoBiometricoEstado copiarCon({
    EtapaBloqueoAjuste? etapa,
    bool? activo,
    bool? trabajando,
    bool? noConfirmado,
  }) => BloqueoBiometricoEstado(
    etapa: etapa ?? this.etapa,
    activo: activo ?? this.activo,
    trabajando: trabajando ?? this.trabajando,
    noConfirmado: noConfirmado ?? this.noConfirmado,
  );

  @override
  bool operator ==(Object other) =>
      other is BloqueoBiometricoEstado &&
      other.etapa == etapa &&
      other.activo == activo &&
      other.trabajando == trabajando &&
      other.noConfirmado == noConfirmado;

  @override
  int get hashCode => Object.hash(etapa, activo, trabajando, noConfirmado);
}

/// El interruptor «Desbloquear con huella o rostro» de ajustes de cuenta.
class BloqueoBiometricoCubit extends Cubit<BloqueoBiometricoEstado> {
  BloqueoBiometricoCubit(this._bloqueo, {required this.motivoActivacion})
    : super(const BloqueoBiometricoEstado());

  final BloqueoBiometrico _bloqueo;

  /// Frase del aviso del sistema al activar (ya en español).
  final String motivoActivacion;

  Future<void> cargar() async {
    final disponibilidad = await _bloqueo.disponibilidad();
    final activo = await _bloqueo.activo();
    if (isClosed) return;
    emit(
      BloqueoBiometricoEstado(
        etapa: switch (disponibilidad) {
          DisponibilidadBiometria.disponible => EtapaBloqueoAjuste.listo,
          DisponibilidadBiometria.sinRegistrar =>
            EtapaBloqueoAjuste.sinRegistrar,
          DisponibilidadBiometria.sinHardware => EtapaBloqueoAjuste.sinHardware,
        },
        // Sin biometría el bloqueo no puede estar activo: se muestra apagado.
        activo: activo && disponibilidad == DisponibilidadBiometria.disponible,
      ),
    );
  }

  Future<void> cambiar(bool quiereActivar) async {
    if (state.trabajando || state.etapa != EtapaBloqueoAjuste.listo) return;
    emit(state.copiarCon(trabajando: true, noConfirmado: false));
    if (quiereActivar) {
      final ok = await _bloqueo.activar(motivo: motivoActivacion);
      if (isClosed) return;
      emit(state.copiarCon(trabajando: false, activo: ok, noConfirmado: !ok));
    } else {
      await _bloqueo.desactivar();
      if (isClosed) return;
      emit(state.copiarCon(trabajando: false, activo: false));
    }
  }
}
