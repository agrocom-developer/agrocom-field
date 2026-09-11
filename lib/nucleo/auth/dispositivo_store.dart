import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// `uuid_dispositivo` de `POST /api/auth/token` — se genera una sola vez y
/// se reutiliza en cada intento de login. Nunca se regenera: si se
/// regenerara, el servidor vería cada reintento como un dispositivo nuevo
/// (ver `docs/decisiones/0005-selector-rol-flavor-auxiliar.md` de este
/// repo, "reintentar con el mismo `uuid_dispositivo` revoca el token
/// anterior"). Mismo mecanismo de almacenamiento que `TokenStore`.
abstract class DispositivoStore {
  Future<String> obtenerUuidDispositivo();
}

class DispositivoStoreSeguro implements DispositivoStore {
  DispositivoStoreSeguro([FlutterSecureStorage? almacenamiento, Uuid? uuid])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage(),
      _uuid = uuid ?? const Uuid();

  final FlutterSecureStorage _almacenamiento;
  final Uuid _uuid;
  static const _clave = 'uuid_dispositivo';

  @override
  Future<String> obtenerUuidDispositivo() async {
    final existente = await _almacenamiento.read(key: _clave);
    if (existente != null) return existente;

    final nuevo = _uuid.v4();
    await _almacenamiento.write(key: _clave, value: nuevo);
    return nuevo;
  }
}
