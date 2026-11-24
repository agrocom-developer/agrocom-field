import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token de push del aparato. Es un identificador de la cuenta en el
/// servicio de avisos: vive solo en almacenamiento seguro (Keychain/Keystore),
/// nunca en `shared_preferences`, logs ni reportes de error.
abstract class TokenPushStore {
  Future<String?> leer();
  Future<void> guardar(String token);
  Future<void> borrar();
}

class TokenPushStoreSeguro implements TokenPushStore {
  TokenPushStoreSeguro([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const _clave = 'token_push';

  @override
  Future<String?> leer() => _almacenamiento.read(key: _clave);

  @override
  Future<void> guardar(String token) =>
      _almacenamiento.write(key: _clave, value: token);

  @override
  Future<void> borrar() => _almacenamiento.delete(key: _clave);
}

/// En memoria, para el modo demo y las pruebas.
class TokenPushEnMemoria implements TokenPushStore {
  TokenPushEnMemoria([this.token]);

  String? token;

  @override
  Future<String?> leer() async => token;

  @override
  Future<void> guardar(String nuevo) async => token = nuevo;

  @override
  Future<void> borrar() async => token = null;
}
