import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/acceso_repositorio.dart';

/// En qué punto del recorrido de entrada está la app.
enum EtapaArranque {
  /// Leyendo la sesión guardada (la splash está en pantalla).
  resolviendo,

  /// Primer uso: presentación de tres pasos.
  onboarding,

  /// Sin sesión: ingreso o registro.
  acceso,

  /// Con sesión: navegación principal.
  dentro,

  /// No se pudo leer el estado guardado.
  error,
}

class ArranqueEstado {
  const ArranqueEstado(this.etapa, {this.sesion});

  final EtapaArranque etapa;
  final SesionCliente? sesion;

  @override
  bool operator ==(Object other) =>
      other is ArranqueEstado && other.etapa == etapa && other.sesion == sesion;

  @override
  int get hashCode => Object.hash(etapa, sesion);
}

/// Decide qué ve la persona al abrir la app y mantiene esa decisión mientras
/// entra, se registra o cierra sesión. Vive por encima de la navegación.
class ArranqueCubit extends Cubit<ArranqueEstado> {
  ArranqueCubit(this._acceso)
    : super(const ArranqueEstado(EtapaArranque.resolviendo));

  final AccesoRepositorio _acceso;

  Future<void> resolver() async {
    emit(const ArranqueEstado(EtapaArranque.resolviendo));
    try {
      final sesion = await _acceso.sesionActual();
      if (sesion != null) {
        emit(ArranqueEstado(EtapaArranque.dentro, sesion: sesion));
        return;
      }
      final visto = await _acceso.onboardingVisto();
      emit(
        ArranqueEstado(visto ? EtapaArranque.acceso : EtapaArranque.onboarding),
      );
    } on Object {
      emit(const ArranqueEstado(EtapaArranque.error));
    }
  }

  void onboardingTerminado() =>
      emit(const ArranqueEstado(EtapaArranque.acceso));

  void sesionIniciada(SesionCliente sesion) =>
      emit(ArranqueEstado(EtapaArranque.dentro, sesion: sesion));

  /// El servidor rechazó el token (venció o lo revocaron): se vuelve al
  /// ingreso sin llamar al servidor.
  void sesionVencida() => emit(const ArranqueEstado(EtapaArranque.acceso));

  Future<void> cerrarSesion() async {
    try {
      await _acceso.cerrarSesion();
    } on Object {
      // Aunque falle la revocación remota, la persona sale de la app.
    }
    emit(const ArranqueEstado(EtapaArranque.acceso));
  }
}
