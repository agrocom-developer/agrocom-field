import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Si la persona activó el desbloqueo con huella o rostro en este teléfono.
/// Vive en el almacenamiento seguro, junto al token, y se borra con él: es una
/// preferencia de seguridad, no de interfaz (nunca en `shared_preferences`).
abstract interface class BloqueoBiometricoStore {
  Future<bool> leer();
  Future<void> guardar(bool activo);
}

class BloqueoBiometricoStoreSeguro implements BloqueoBiometricoStore {
  BloqueoBiometricoStoreSeguro([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const _clave = 'bloqueo_biometrico';

  @override
  Future<bool> leer() async => await _almacenamiento.read(key: _clave) == '1';

  @override
  Future<void> guardar(bool activo) => activo
      ? _almacenamiento.write(key: _clave, value: '1')
      : _almacenamiento.delete(key: _clave);
}

class BloqueoBiometricoStoreEnMemoria implements BloqueoBiometricoStore {
  BloqueoBiometricoStoreEnMemoria({bool activo = false}) : _activo = activo;

  bool _activo;

  @override
  Future<bool> leer() async => _activo;

  @override
  Future<void> guardar(bool activo) async => _activo = activo;
}
