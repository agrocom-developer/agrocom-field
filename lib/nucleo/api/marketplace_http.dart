import 'package:dio/dio.dart';

import '../marketplace/dominio/falla.dart';
import 'api_client.dart';
import 'api_excepcion.dart';

/// Puerta de las implementaciones de red de la superficie del proveedor
/// hacia [ApiClient]: devuelve JSON ya decodificado y traduce los fallos de
/// red a [FallaMarketplace] (`SinConexion` u `OperacionRechazada`, con un
/// mensaje en español que la pantalla puede mostrar tal cual).
///
/// Es el único punto de la superficie del proveedor que conoce `dio`; los
/// repositorios de cada feature trabajan con mapas JSON y con el dominio.
class MarketplaceHttp {
  MarketplaceHttp(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> obtener(
    String ruta, {
    Map<String, dynamic>? query,
  }) => proteger(() async {
    final r = await _api.get(ruta, query: query);
    return _mapa(r.data);
  });

  Future<Map<String, dynamic>> enviar(String ruta, {Object? datos}) =>
      proteger(() async {
        final r = await _api.post(ruta, data: datos);
        return _mapa(r.data);
      });

  Future<Map<String, dynamic>> guardar(String ruta, {Object? datos}) =>
      proteger(() async {
        final r = await _api.put(ruta, data: datos);
        return _mapa(r.data);
      });

  /// Borra un recurso (`DELETE`); las respuestas `204` no traen cuerpo.
  Future<void> borrar(String ruta) => proteger(() async {
    await _api.delete(ruta);
  });

  /// Sube un archivo (multipart) con sus campos de texto. Con [reemplazar]
  /// usa `PUT` (la foto de perfil); si no, `POST`.
  Future<Map<String, dynamic>> subir(
    String ruta, {
    required Map<String, Object?> campos,
    required String campoArchivo,
    required List<int> bytes,
    String nombreArchivo = 'foto.jpg',
    bool reemplazar = false,
  }) => proteger(() async {
    final formulario = FormData.fromMap({
      for (final e in campos.entries)
        if (e.value != null) e.key: e.value,
      campoArchivo: MultipartFile.fromBytes(bytes, filename: nombreArchivo),
    });
    final r = reemplazar
        ? await _api.put(ruta, data: formulario)
        : await _api.post(ruta, data: formulario);
    return _mapa(r.data);
  });

  /// Ejecuta [llamada] y convierte cualquier [ApiExcepcion] en la falla de
  /// dominio equivalente. Las fallas de dominio ya traducidas pasan intactas.
  static Future<T> proteger<T>(Future<T> Function() llamada) async {
    try {
      return await llamada();
    } on ApiExcepcionRed {
      throw const SinConexion();
    } on ApiExcepcionServidor catch (e) {
      throw OperacionRechazada(
        mensajeDeServidor(e.codigo, e.cuerpo),
        codigo: e.codigo,
        motivo: codigoDeConflicto(e.cuerpo),
      );
    } on ApiExcepcionDesconocida {
      throw const OperacionRechazada(_mensajeGenerico);
    }
  }

  static const _mensajeGenerico =
      'No pudimos completar la operación. Vuelve a intentarlo en un momento.';

  static Map<String, dynamic> _mapa(Object? datos) =>
      datos is Map ? Map<String, dynamic>.from(datos) : <String, dynamic>{};

  /// El `codigo` de un `409` o `403` (`oferta_no_vigente`,
  /// `solicitud_ya_adjudicada`, `proveedor_no_habilitado`...), si viene.
  static String? codigoDeConflicto(Object? cuerpo) {
    if (cuerpo is Map && cuerpo['codigo'] is String) {
      return cuerpo['codigo'] as String;
    }
    return null;
  }

  /// Mensaje en español para una respuesta de error del servidor. Un `422` o
  /// un conflicto traen el motivo escrito por el servidor; el resto, un texto
  /// fijo según el código, para no mostrar jerga técnica.
  static String mensajeDeServidor(int codigo, Object? cuerpo) {
    final propio = _mensaje(cuerpo);
    return switch (codigo) {
      401 => 'Tu sesión venció. Ingresa de nuevo.',
      403 => propio ?? 'Esta cuenta no tiene permiso para hacer esto.',
      404 => 'No encontramos lo que buscas. Puede haber cambiado.',
      409 =>
        propio ??
            'Esto cambió mientras lo mirabas. Actualiza y vuelve a intentarlo.',
      422 => propio ?? 'Revisa los datos y vuelve a intentarlo.',
      429 => 'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      >= 500 => 'Tuvimos un problema. Vuelve a intentarlo en un momento.',
      _ => _mensajeGenerico,
    };
  }

  static String? _mensaje(Object? cuerpo) {
    if (cuerpo is Map && cuerpo['message'] is String) {
      final m = (cuerpo['message'] as String).trim();
      if (m.isNotEmpty) return m;
    }
    return null;
  }

  /// Errores por campo de un `422`: `{campo: primer mensaje}`.
  static Map<String, String> erroresPorCampo(Object? cuerpo) {
    final salida = <String, String>{};
    if (cuerpo is Map && cuerpo['errors'] is Map) {
      (cuerpo['errors'] as Map).forEach((campo, mensajes) {
        if (mensajes is List && mensajes.isNotEmpty) {
          salida['$campo'] = '${mensajes.first}';
        }
      });
    }
    return salida;
  }
}
