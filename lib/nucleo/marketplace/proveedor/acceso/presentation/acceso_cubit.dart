import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/bloqueo_biometrico.dart';
import '../domain/acceso_proveedor.dart';

sealed class AccesoEstado {
  const AccesoEstado();
}

/// Revisando si hay una sesión guardada.
final class AccesoVerificando extends AccesoEstado {
  const AccesoVerificando();
}

/// Nadie dentro: se muestra el ingreso. [mensaje] explica el último fallo.
final class AccesoSinSesion extends AccesoEstado {
  const AccesoSinSesion({
    this.mensaje,
    this.enviando = false,
    this.sesionVencida = false,
  });

  final String? mensaje;
  final bool enviando;
  final bool sesionVencida;
}

/// Hay sesión guardada y el bloqueo biométrico está activo: no se lee el token
/// hasta reconocer a la persona (ADR 0026).
final class AccesoBloqueado extends AccesoEstado {
  const AccesoBloqueado({this.desbloqueando = false});

  final bool desbloqueando;
}

final class AccesoDentro extends AccesoEstado {
  const AccesoDentro(this.sesion);

  final SesionProveedor sesion;
}

/// La puerta de la app real: decide entre el ingreso y la superficie del
/// proveedor según haya o no una sesión válida.
class AccesoCubit extends Cubit<AccesoEstado> {
  AccesoCubit(
    this._acceso,
    this._l10n, {
    Stream<void>? sesionExpirada,
    BloqueoBiometrico? bloqueo,
  }) : _bloqueo = bloqueo,
       super(const AccesoVerificando()) {
    _sub = sesionExpirada?.listen((_) {
      if (state is AccesoDentro) {
        _bloqueo?.olvidar();
        emit(
          AccesoSinSesion(
            sesionVencida: true,
            mensaje: _l10n.proveedorAccesoSesionVencioEntraNuevo,
          ),
        );
      }
    });
  }

  final AppLocalizations _l10n;
  final AccesoProveedorRepositorio _acceso;
  final BloqueoBiometrico? _bloqueo;
  StreamSubscription<void>? _sub;

  Future<void> iniciar() async {
    final bloqueo = _bloqueo;
    if (bloqueo != null && await bloqueo.activo()) {
      emit(const AccesoBloqueado());
      await desbloquear();
      return;
    }
    await _leerSesion();
  }

  /// Pide huella o rostro y, solo si coinciden, lee la sesión guardada. Si
  /// cancela, queda bloqueado y puede reintentar; si ya no hay biometría en el
  /// teléfono, pasa al ingreso con contraseña.
  Future<void> desbloquear() async {
    final bloqueo = _bloqueo;
    if (bloqueo == null) return _leerSesion();
    emit(const AccesoBloqueado(desbloqueando: true));
    final resultado = await bloqueo.desbloquear(
      motivo: _l10n.biometriaMotivoDesbloqueo,
    );
    if (isClosed) return;
    switch (resultado) {
      case ResultadoDesbloqueo.noAplica:
      case ResultadoDesbloqueo.desbloqueado:
        await _leerSesion();
      case ResultadoDesbloqueo.cancelado:
        emit(const AccesoBloqueado());
      case ResultadoDesbloqueo.usarContrasena:
        await usarContrasena(mensaje: _l10n.biometriaUsaContrasena);
    }
  }

  /// Sale del bloqueo por el ingreso normal: cierra la sesión guardada (revoca
  /// el dispositivo si hay red) y pide usuario y contraseña.
  Future<void> usarContrasena({String? mensaje}) async {
    await salir();
    if (!isClosed && mensaje != null) emit(AccesoSinSesion(mensaje: mensaje));
  }

  Future<void> _leerSesion() async {
    try {
      final sesion = await _acceso.sesionActual();
      if (isClosed) return;
      emit(sesion == null ? const AccesoSinSesion() : AccesoDentro(sesion));
    } on Object {
      // Sin red al abrir: hay un token guardado, pero no se puede validar.
      // Se muestra el ingreso; lo pendiente de subir sigue guardado.
      if (!isClosed) emit(const AccesoSinSesion());
    }
  }

  Future<void> ingresar(String usuario, String contrasena) async {
    emit(const AccesoSinSesion(enviando: true));
    try {
      final sesion = await _acceso.iniciarSesion(
        usuario: usuario,
        contrasena: contrasena,
      );
      emit(AccesoDentro(sesion));
    } on AccesoProveedorExcepcion catch (e) {
      emit(AccesoSinSesion(mensaje: _mensaje(e)));
    }
  }

  /// Después del alta, la sesión ya quedó iniciada.
  Future<void> alRegistrarse() => iniciar();

  Future<void> salir() async {
    await _bloqueo?.olvidar();
    await _acceso.cerrarSesion();
    if (!isClosed) emit(const AccesoSinSesion());
  }

  String _mensaje(AccesoProveedorExcepcion e) => switch (e.motivo) {
    MotivoFalloAcceso.credencialesInvalidas =>
      _l10n.proveedorAccesoUsuarioContrasenaIncorrectosRevisa,
    MotivoFalloAcceso.sinConexion =>
      _l10n.proveedorAccesoSinConexionNecesitasSenal,
    MotivoFalloAcceso.cuentaAjena =>
      e.mensaje ?? _l10n.proveedorAccesoEstaCuentaEstaApp,
    _ => e.mensaje ?? _l10n.proveedorAccesoPudimosEntrarIntentaNuevo,
  };

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
