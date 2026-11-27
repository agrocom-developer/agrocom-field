import 'biometria.dart';
import 'bloqueo_biometrico_store.dart';

/// Cómo terminó un intento de abrir la app con el bloqueo activo.
enum ResultadoDesbloqueo {
  /// El bloqueo no está activo: se sigue sin preguntar nada.
  noAplica,

  /// Se reconoció a la persona: se puede leer el token guardado.
  desbloqueado,

  /// No se reconoció o cerró el aviso: puede reintentar.
  cancelado,

  /// Ya no hay biometría en el teléfono o falló el sistema: se pide la
  /// contraseña, como en cualquier ingreso.
  usarContrasena,
}

/// Desbloqueo local de la sesión con huella o rostro (ADR 0026).
///
/// El token de dispositivo sigue en Keychain/Keystore; este servicio decide si
/// la app lo lee ya o antes pide reconocer a la persona. El servidor no recibe
/// nada. Si el token venció o lo revocaron, el desbloqueo no cambia nada: la
/// lectura de la sesión devuelve `401` y la app cae al ingreso normal.
class BloqueoBiometrico {
  BloqueoBiometrico(this._biometria, this._store);

  final Biometria _biometria;
  final BloqueoBiometricoStore _store;

  Future<bool> activo() => _store.leer();

  /// Ofrecer la opción en ajustes solo si hay con qué desbloquear.
  Future<DisponibilidadBiometria> disponibilidad() =>
      _biometria.disponibilidad();

  /// Activa el bloqueo solo si la persona se reconoce en este momento: así no
  /// se deja activado algo que luego no podría abrir.
  Future<bool> activar({required String motivo}) async {
    if (await _biometria.disponibilidad() !=
        DisponibilidadBiometria.disponible) {
      return false;
    }
    if (await _biometria.autenticar(motivo: motivo) !=
        ResultadoBiometria.exito) {
      return false;
    }
    await _store.guardar(true);
    return true;
  }

  Future<void> desactivar() => _store.guardar(false);

  /// Cerrar sesión o perder el token borra también la preferencia.
  Future<void> olvidar() => _store.guardar(false);

  Future<ResultadoDesbloqueo> desbloquear({required String motivo}) async {
    if (!await _store.leer()) return ResultadoDesbloqueo.noAplica;
    if (await _biometria.disponibilidad() !=
        DisponibilidadBiometria.disponible) {
      // Quitaron la huella o el rostro del teléfono: el bloqueo ya no tiene
      // con qué abrirse. Se apaga y se entra con contraseña.
      await _store.guardar(false);
      return ResultadoDesbloqueo.usarContrasena;
    }
    switch (await _biometria.autenticar(motivo: motivo)) {
      case ResultadoBiometria.exito:
        return ResultadoDesbloqueo.desbloqueado;
      case ResultadoBiometria.cancelado:
        return ResultadoDesbloqueo.cancelado;
      case ResultadoBiometria.noDisponible:
        await _store.guardar(false);
        return ResultadoDesbloqueo.usarContrasena;
      case ResultadoBiometria.error:
        return ResultadoDesbloqueo.usarContrasena;
    }
  }
}
