import '../../nucleo/api/api_client.dart';
import '../../nucleo/api/api_excepcion.dart';
import '../../nucleo/marketplace/dominio/dominio.dart';

/// Puerta de las implementaciones de red del flavor cliente hacia
/// [ApiClient]: devuelve JSON ya decodificado y traduce los fallos de red a
/// [FallaMarketplace] (`SinConexion` u `OperacionRechazada` con un mensaje en
/// español que la pantalla puede mostrar tal cual).
///
/// Es el único punto de `cliente/` que conoce `dio`: los repositorios de
/// cada feature trabajan con mapas JSON y con el dominio.
class ClienteHttp {
  ClienteHttp(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> obtener(
    String ruta, {
    Map<String, dynamic>? query,
  }) => proteger(() async {
    final r = await _api.get(ruta, query: query);
    return _mapa(r.data);
  });

  /// Como [obtener], pero un `404` devuelve `null` en vez de fallar: sirve
  /// para recursos que pueden no existir (la disputa de un servicio).
  Future<Map<String, dynamic>?> obtenerOpcional(String ruta) =>
      proteger(() async {
        try {
          final r = await _api.get(ruta);
          return _mapa(r.data);
        } on ApiExcepcionServidor catch (e) {
          if (e.codigo == 404) return null;
          rethrow;
        }
      });

  /// Envía un `POST`. Con [conflictoComoExito], un `409` (la operación ya
  /// estaba registrada) devuelve `{conflicto: true}` en vez de fallar: así un
  /// reintento idempotente no se ve como error.
  Future<Map<String, dynamic>> enviar(
    String ruta, {
    Object? datos,
    bool conflictoComoExito = false,
  }) => proteger(() async {
    try {
      final r = await _api.post(ruta, data: datos);
      return _mapa(r.data);
    } on ApiExcepcionServidor catch (e) {
      if (conflictoComoExito && e.codigo == 409) return {claveConflicto: true};
      rethrow;
    }
  });

  static const claveConflicto = 'conflicto';

  Future<void> borrar(String ruta) => proteger(() async {
    await _api.delete(ruta);
  });

  /// Ejecuta [llamada] y convierte cualquier [ApiExcepcion] en la falla de
  /// dominio equivalente. Las fallas de dominio ya traducidas pasan intactas.
  static Future<T> proteger<T>(Future<T> Function() llamada) async {
    try {
      return await llamada();
    } on ApiExcepcionRed {
      throw const SinConexion();
    } on ApiExcepcionServidor catch (e) {
      throw OperacionRechazada(mensajeDeServidor(e.codigo, e.cuerpo));
    } on ApiExcepcionDesconocida {
      throw const OperacionRechazada(_mensajeGenerico);
    }
  }

  static const _mensajeGenerico =
      'No pudimos completar la operación. Intenta de nuevo en un momento.';

  static Map<String, dynamic> _mapa(Object? datos) =>
      datos is Map ? Map<String, dynamic>.from(datos) : <String, dynamic>{};

  /// Mensaje en español para una respuesta de error del servidor. Un `422`
  /// trae el motivo escrito por el servidor; el resto, un texto fijo según
  /// el código, para no mostrar jerga técnica.
  static String mensajeDeServidor(int codigo, Object? cuerpo) {
    return switch (codigo) {
      401 => 'Tu sesión venció. Entra de nuevo.',
      403 => 'Esta cuenta no tiene permiso para hacer esto.',
      404 => 'No encontramos lo que buscas. Puede haber cambiado.',
      409 => 'Esta operación ya se había registrado.',
      422 =>
        mensajeDeValidacion(cuerpo) ?? 'Revisa los datos e intenta de nuevo.',
      429 => 'Demasiados intentos. Espera un momento e intenta de nuevo.',
      >= 500 => 'El servidor tuvo un problema. Intenta de nuevo en un momento.',
      _ => _mensajeGenerico,
    };
  }

  /// El `message` de un `422` de Laravel, si viene.
  static String? mensajeDeValidacion(Object? cuerpo) {
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
