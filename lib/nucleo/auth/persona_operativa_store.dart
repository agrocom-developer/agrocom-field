import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// `persona_id` de `UsuarioCampo` (`POST /api/auth/token`, ver
/// `docs/api/openapi.yaml`) — la persona operativa del módulo `Personal` que
/// HU-05 necesita para completar `AperturaSesion.piloto_id`. Nullable: no
/// todo usuario logueado tiene una persona operativa enlazada. Mismo
/// mecanismo de almacenamiento que [TokenStore]/[DispositivoStore].
abstract class PersonaOperativaStore {
  Future<int?> leerPersonaId();
  Future<void> guardarPersonaId(int? personaId);
  Future<void> borrarPersonaId();
}

class PersonaOperativaStoreSeguro implements PersonaOperativaStore {
  PersonaOperativaStoreSeguro([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const _clave = 'persona_id_operativa';

  @override
  Future<int?> leerPersonaId() async {
    final valor = await _almacenamiento.read(key: _clave);
    return valor == null ? null : int.parse(valor);
  }

  @override
  Future<void> guardarPersonaId(int? personaId) {
    if (personaId == null) return borrarPersonaId();
    return _almacenamiento.write(key: _clave, value: personaId.toString());
  }

  @override
  Future<void> borrarPersonaId() => _almacenamiento.delete(key: _clave);
}
