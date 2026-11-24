import '../../api/marketplace_http.dart';
import '../dominio/dominio.dart';
import '../foto_limite.dart';

/// Las fotos que el cliente sube de su terreno para que el piloto vea el
/// estado antes de ofertar. Solo el cliente dueño escribe.
abstract interface class FotosTerrenoRepositorio {
  /// Máximo de fotos por terreno.
  static const maximo = 8;

  Future<FotoTerreno> subir(
    int terrenoId,
    List<int> bytes, {
    String? descripcion,
  });

  Future<void> borrar(int terrenoId, int fotoId);
}

class FotosTerrenoRed implements FotosTerrenoRepositorio {
  FotosTerrenoRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<FotoTerreno> subir(
    int terrenoId,
    List<int> bytes, {
    String? descripcion,
  }) async {
    validarTamanoDeFoto(bytes);
    final r = await _http.subir(
      '/api/terrenos/$terrenoId/fotos',
      campos: {'descripcion': descripcion},
      campoArchivo: 'archivo',
      bytes: bytes,
    );
    final foto = r['foto'];
    if (foto is! Map) {
      throw const OperacionRechazada('No pudimos guardar la foto.');
    }
    return FotoTerreno.desdeJson(Map<String, dynamic>.from(foto));
  }

  @override
  Future<void> borrar(int terrenoId, int fotoId) =>
      _http.borrar('/api/terrenos/$terrenoId/fotos/$fotoId');
}

/// En memoria, con el mismo tope de 8 fotos por terreno que el servidor.
class FotosTerrenoDemo implements FotosTerrenoRepositorio {
  final _porTerreno = <int, List<FotoTerreno>>{};
  int _siguiente = 1;

  List<FotoTerreno> de(int terrenoId) =>
      List.unmodifiable(_porTerreno[terrenoId] ?? const []);

  @override
  Future<FotoTerreno> subir(
    int terrenoId,
    List<int> bytes, {
    String? descripcion,
  }) async {
    validarTamanoDeFoto(bytes);
    final fotos = _porTerreno.putIfAbsent(terrenoId, () => []);
    if (fotos.length >= FotosTerrenoRepositorio.maximo) {
      throw const OperacionRechazada(
        'Este terreno ya tiene el máximo de fotos. Borra una para subir otra.',
        codigo: 422,
      );
    }
    final foto = FotoTerreno(
      id: _siguiente++,
      url: '/api/terrenos/fotos/${_siguiente - 1}/archivo',
      descripcion: descripcion,
    );
    fotos.add(foto);
    return foto;
  }

  @override
  Future<void> borrar(int terrenoId, int fotoId) async {
    final fotos = _porTerreno[terrenoId];
    final antes = fotos?.length ?? 0;
    fotos?.removeWhere((f) => f.id == fotoId);
    if (fotos == null || fotos.length == antes) {
      throw const OperacionRechazada(
        'No encontramos lo que buscas. Puede haber cambiado.',
        codigo: 404,
      );
    }
  }
}
