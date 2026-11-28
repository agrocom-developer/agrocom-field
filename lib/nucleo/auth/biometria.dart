import 'package:local_auth/local_auth.dart';

/// Si el teléfono puede pedir huella o rostro ahora mismo.
enum DisponibilidadBiometria {
  disponible,

  /// El teléfono no tiene lector de huella ni de rostro.
  sinHardware,

  /// Tiene lector, pero la persona no registró ninguna huella ni rostro.
  sinRegistrar,
}

enum ResultadoBiometria {
  exito,

  /// La persona cerró el aviso, no reconoció su huella o se acabó el tiempo.
  cancelado,

  /// Dejó de haber biometría registrada (o de haber lector).
  noDisponible,

  /// El sistema falló por otra causa.
  error,
}

/// Pide al sistema una huella o un rostro. **Solo confirma localmente**: no
/// entrega ninguna plantilla ni dato biométrico, y nada de esto viaja al
/// servidor (ADR 0026). Abstracta para fakear sin canal de plataforma.
abstract interface class Biometria {
  Future<DisponibilidadBiometria> disponibilidad();

  /// [motivo] es la frase que muestra el sistema en su aviso.
  Future<ResultadoBiometria> autenticar({required String motivo});
}

/// Envuelve `local_auth`. `biometricOnly` evita que el aviso acepte el PIN del
/// teléfono: el PIN no prueba que sea la misma persona que activó el bloqueo
/// y el camino alterno es el ingreso con contraseña de Agrocom.
class BiometriaLocalAuth implements Biometria {
  BiometriaLocalAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<DisponibilidadBiometria> disponibilidad() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return DisponibilidadBiometria.sinHardware;
      }
      final registradas = await _auth.getAvailableBiometrics();
      return registradas.isEmpty
          ? DisponibilidadBiometria.sinRegistrar
          : DisponibilidadBiometria.disponible;
    } on LocalAuthException {
      return DisponibilidadBiometria.sinHardware;
    }
  }

  @override
  Future<ResultadoBiometria> autenticar({required String motivo}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: true,
      );
      return ok ? ResultadoBiometria.exito : ResultadoBiometria.cancelado;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => ResultadoBiometria.cancelado,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noCredentialsSet =>
          ResultadoBiometria.noDisponible,
        _ => ResultadoBiometria.error,
      };
    }
  }
}

/// Biometría de mentira para pruebas y modo demo.
class BiometriaFalsa implements Biometria {
  BiometriaFalsa({
    this.estado = DisponibilidadBiometria.disponible,
    this.resultado = ResultadoBiometria.exito,
  });

  DisponibilidadBiometria estado;
  ResultadoBiometria resultado;
  int intentos = 0;

  @override
  Future<DisponibilidadBiometria> disponibilidad() async => estado;

  @override
  Future<ResultadoBiometria> autenticar({required String motivo}) async {
    intentos++;
    return resultado;
  }
}
