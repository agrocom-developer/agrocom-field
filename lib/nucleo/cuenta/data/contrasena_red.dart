import '../../api/marketplace_http.dart';
import '../domain/contrasena_repositorio.dart';

/// Contra la API: `POST /api/cuenta/contrasena/codigo` y
/// `PUT /api/cuenta/contrasena`. Nunca registra la contraseña ni el código.
class ContrasenaRed implements ContrasenaRepositorio {
  ContrasenaRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<CodigoEnviado> pedirCodigo(CanalCodigo canal) async {
    final r = await _http.enviar(
      '/api/cuenta/contrasena/codigo',
      datos: {'canal': canal.name},
    );
    return CodigoEnviado('${r['destino'] ?? ''}');
  }

  @override
  Future<void> cambiar({
    required String codigo,
    required String passwordNueva,
  }) async {
    await _http.guardar(
      '/api/cuenta/contrasena',
      datos: {'codigo': codigo, 'password_nueva': passwordNueva},
    );
  }
}
