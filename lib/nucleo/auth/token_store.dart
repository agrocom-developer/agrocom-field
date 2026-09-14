import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token por dispositivo (Sanctum, no caduca por tiempo — ver docs/vision.md,
/// "Roles que usan esta app"). Nunca login de usuario/contraseña por sesión.
abstract class TokenStore {
  Future<String?> leerToken();
  Future<void> guardarToken(String token);
  Future<void> borrarToken();
}

class TokenStoreSeguro implements TokenStore {
  TokenStoreSeguro([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const _clave = 'token_dispositivo';

  @override
  Future<String?> leerToken() => _almacenamiento.read(key: _clave);

  @override
  Future<void> guardarToken(String token) =>
      _almacenamiento.write(key: _clave, value: token);

  @override
  Future<void> borrarToken() => _almacenamiento.delete(key: _clave);
}
