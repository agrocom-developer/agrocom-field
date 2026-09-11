import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'rol_activo.dart';

/// Rol activo devuelto en el `201` de `POST /api/auth/token` — con o sin
/// selector de por medio (ADR 0005 de este repo). Mismo mecanismo que
/// [TokenStore]/[PersonaOperativaStore] (`flutter_secure_storage`); pieza
/// de persistencia que ese ADR dejaba señalada sin implementar
/// (sección Consecuencias).
abstract class RolActivoStore {
  Future<RolActivo?> leerRolActivo();
  Future<void> guardarRolActivo(RolActivo rolActivo);
  Future<void> borrarRolActivo();
}

class RolActivoStoreSeguro implements RolActivoStore {
  RolActivoStoreSeguro([FlutterSecureStorage? almacenamiento])
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacenamiento;
  static const _clave = 'rol_activo';

  @override
  Future<RolActivo?> leerRolActivo() async {
    final valor = await _almacenamiento.read(key: _clave);
    if (valor == null) return null;
    return RolActivo.fromJson(jsonDecode(valor) as Map<String, dynamic>);
  }

  @override
  Future<void> guardarRolActivo(RolActivo rolActivo) =>
      _almacenamiento.write(key: _clave, value: jsonEncode(rolActivo.toJson()));

  @override
  Future<void> borrarRolActivo() => _almacenamiento.delete(key: _clave);
}
