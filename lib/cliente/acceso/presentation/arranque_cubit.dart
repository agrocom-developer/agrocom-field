import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/auth/bloqueo_biometrico.dart';
import '../../../nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import '../domain/acceso_repositorio.dart';

/// En qué punto del recorrido de entrada está la app.
enum EtapaArranque {
  /// Leyendo la sesión guardada (la splash está en pantalla).
  resolviendo,

  /// Primer uso: presentación de tres pasos.
  onboarding,

  /// Sin sesión: ingreso o registro.
  acceso,

  /// Hay sesión guardada y el bloqueo biométrico está activo: no se lee el
  /// token hasta reconocer a la persona (ADR 0026).
  bloqueada,

  /// Con sesión: navegación principal.
  dentro,

  /// No se pudo leer el estado guardado.
  error,

  /// La cuenta está en los 7 días de gracia de su eliminación: la sesión
  /// solo permite conservarla o cerrar sesión.
  enEliminacion,
}

class ArranqueEstado {
  const ArranqueEstado(this.etapa, {this.sesion, this.desbloqueando = false});

  final EtapaArranque etapa;
  final SesionCliente? sesion;

  /// Con [EtapaArranque.bloqueada]: el aviso del sistema está abierto.
  final bool desbloqueando;

  @override
  bool operator ==(Object other) =>
      other is ArranqueEstado &&
      other.etapa == etapa &&
      other.sesion == sesion &&
      other.desbloqueando == desbloqueando;

  @override
  int get hashCode => Object.hash(etapa, sesion, desbloqueando);
}

/// Decide qué ve la persona al abrir la app y mantiene esa decisión mientras
/// entra, se registra o cierra sesión. Vive por encima de la navegación.
class ArranqueCubit extends Cubit<ArranqueEstado> {
  /// Con [bloqueo] (y [l10n] para el aviso del sistema), al abrir con sesión
  /// guardada se pide huella o rostro antes de leer el token.
  ArranqueCubit(
    this._acceso, {
    BloqueoBiometrico? bloqueo,
    AppLocalizations? l10n,
    RenovadorSesion? renovarSesion,
  }) : _bloqueo = bloqueo,
       _l10n = l10n,
       _renovarSesion = renovarSesion,
       super(const ArranqueEstado(EtapaArranque.resolviendo));

  final AccesoRepositorio _acceso;
  final BloqueoBiometrico? _bloqueo;
  final AppLocalizations? _l10n;

  /// `POST /api/auth/renovar` cuando al token le quedan pocos días; se pide
  /// solo tras reconocer a la persona con la biometría.
  final RenovadorSesion? _renovarSesion;

  Future<void> resolver() async {
    emit(const ArranqueEstado(EtapaArranque.resolviendo));
    final bloqueo = _bloqueo;
    if (bloqueo != null && await bloqueo.activo()) {
      emit(const ArranqueEstado(EtapaArranque.bloqueada));
      await desbloquear();
      return;
    }
    await _leerSesion();
  }

  /// Pide huella o rostro; solo si coinciden se lee la sesión guardada.
  Future<void> desbloquear() async {
    final bloqueo = _bloqueo;
    if (bloqueo == null) return _leerSesion();
    emit(const ArranqueEstado(EtapaArranque.bloqueada, desbloqueando: true));
    final resultado = await bloqueo.desbloquear(
      motivo: _l10n?.biometriaMotivoDesbloqueo ?? '',
    );
    if (isClosed) return;
    switch (resultado) {
      case ResultadoDesbloqueo.noAplica:
        await _leerSesion();
      case ResultadoDesbloqueo.desbloqueado:
        // La biometría nunca llega al servidor: reutiliza el token guardado
        // y, si le quedan pocos días, lo renueva. Una falla no impide entrar.
        try {
          await _renovarSesion?.call();
        } on Object {
          // La sesión sigue con el token guardado.
        }
        if (isClosed) return;
        await _leerSesion();
      case ResultadoDesbloqueo.cancelado:
        emit(const ArranqueEstado(EtapaArranque.bloqueada));
      case ResultadoDesbloqueo.usarContrasena:
        await cerrarSesion();
    }
  }

  /// Salida del bloqueo por el ingreso normal con contraseña.
  Future<void> usarContrasena() => cerrarSesion();

  Future<void> _leerSesion() async {
    try {
      final sesion = await _acceso.sesionActual();
      if (sesion != null) {
        emit(_estadoDe(sesion));
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

  void sesionIniciada(SesionCliente sesion) => emit(_estadoDe(sesion));

  ArranqueEstado _estadoDe(SesionCliente sesion) => ArranqueEstado(
    sesion.enEliminacion ? EtapaArranque.enEliminacion : EtapaArranque.dentro,
    sesion: sesion,
  );

  /// «Conservar mi cuenta» funcionó: se vuelve a leer la sesión, ya sin
  /// restricción.
  Future<void> cuentaConservada() => _leerSesion();

  /// El servidor rechazó el token (venció o lo revocaron): se vuelve al
  /// ingreso sin llamar al servidor.
  void sesionVencida() {
    _bloqueo?.olvidar();
    emit(const ArranqueEstado(EtapaArranque.acceso));
  }

  Future<void> cerrarSesion() async {
    await _bloqueo?.olvidar();
    try {
      await _acceso.cerrarSesion();
    } on Object {
      // Aunque falle la revocación remota, la persona sale de la app.
    }
    emit(const ArranqueEstado(EtapaArranque.acceso));
  }
}
