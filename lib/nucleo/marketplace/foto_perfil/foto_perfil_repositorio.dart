import '../../api/marketplace_http.dart';
import '../foto_limite.dart';

/// Foto de perfil de la cuenta (cliente, piloto, auxiliar o proveedor).
///
/// La URL que devuelve el servidor es firmada y vive 15 minutos: no se
/// guarda; se vuelve a pedir con la sesión (`GET /api/auth/sesion`).
abstract interface class FotoPerfilRepositorio {
  /// La URL firmada de la foto actual, o `null` si la cuenta no tiene.
  Future<String?> actual();

  /// Sube o reemplaza la foto. [bytes] ya vienen comprimidos a menos de
  /// 300 KB. Devuelve la URL firmada nueva.
  Future<String> subir(List<int> bytes);

  /// Quita la foto. Idempotente.
  Future<void> quitar();
}

class FotoPerfilRed implements FotoPerfilRepositorio {
  FotoPerfilRed(this._http);

  final MarketplaceHttp _http;

  static const _ruta = '/api/perfil/foto';

  @override
  Future<String?> actual() async {
    final sesion = await _http.obtener('/api/auth/sesion');
    final usuario = sesion['usuario'];
    if (usuario is! Map) return null;
    return usuario['foto_url'] as String?;
  }

  @override
  Future<String> subir(List<int> bytes) async {
    validarTamanoDeFoto(bytes);
    final r = await _http.subir(
      _ruta,
      campos: const {},
      campoArchivo: 'archivo',
      bytes: bytes,
      reemplazar: true,
    );
    return '${r['foto_url']}';
  }

  @override
  Future<void> quitar() => _http.borrar(_ruta);
}

/// En memoria, para el modo demo y las pruebas.
class FotoPerfilDemo implements FotoPerfilRepositorio {
  FotoPerfilDemo([this._url]);

  String? _url;
  int _version = 0;

  @override
  Future<String?> actual() async => _url;

  @override
  Future<String> subir(List<int> bytes) async {
    validarTamanoDeFoto(bytes);
    return _url = '/api/personas/0/foto?version=${++_version}';
  }

  @override
  Future<void> quitar() async => _url = null;
}
