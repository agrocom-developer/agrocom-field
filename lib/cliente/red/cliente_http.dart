import 'package:dio/dio.dart' show FormData, MultipartFile;

import '../../nucleo/api/api_client.dart';
import '../../nucleo/api/api_excepcion.dart';
import '../../nucleo/marketplace/dominio/dominio.dart';
import '../ofertas/domain/oferta_recibida.dart';
import '../seguimiento/domain/seguimiento.dart';

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
  /// para recursos que pueden no existir (el reclamo de un servicio).
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

  /// Sube un archivo (multipart) con sus campos de texto. Con
  /// [conflictoComoExito], un `409` devuelve `{conflicto: true}`.
  Future<Map<String, dynamic>> subir(
    String ruta, {
    required Map<String, Object?> campos,
    required String campoArchivo,
    required List<int> bytes,
    String nombreArchivo = 'foto.jpg',
  }) => proteger(() async {
    final formulario = FormData.fromMap({
      for (final e in campos.entries)
        if (e.value != null) e.key: e.value,
      campoArchivo: MultipartFile.fromBytes(bytes, filename: nombreArchivo),
    });
    final r = await _api.post(ruta, data: formulario);
    return _mapa(r.data);
  });

  /// Envía un `PUT` (corrige un recurso propio).
  Future<Map<String, dynamic>> reemplazar(String ruta, {Object? datos}) =>
      proteger(() async {
        final r = await _api.put(ruta, data: datos);
        return _mapa(r.data);
      });

  static const claveConflicto = 'conflicto';

  /// Descarga el archivo de [ruta] (una foto de avance o del dron).
  Future<List<int>> descargar(String ruta) =>
      proteger(() => _api.getBytes(ruta));

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
      if (e.codigo == 409) {
        final codigo = codigoDeError(e.cuerpo);
        if (codigo == 'chat_cerrado') throw const ChatCerrado();
        if (_codigosDeCambio.contains(codigo)) {
          throw OfertaCambio(
            mensajeDeValidacion(e.cuerpo) ??
                'La oferta cambió. Revisa las ofertas actuales.',
          );
        }
      }
      throw OperacionRechazada(mensajeDeServidor(e.codigo, e.cuerpo));
    } on ApiExcepcionDesconocida {
      throw const OperacionRechazada(_mensajeGenerico);
    }
  }

  /// Respuestas `409` de la negociación: la oferta o la solicitud cambiaron
  /// mientras el cliente decidía (ADR 0016).
  static const _codigosDeCambio = {
    'oferta_no_vigente',
    'solicitud_ya_adjudicada',
    'equipo_no_disponible',
  };

  /// El `codigo` de máquina que el servidor agrega a un error, si viene.
  static String? codigoDeError(Object? cuerpo) =>
      cuerpo is Map && cuerpo['codigo'] is String
      ? cuerpo['codigo'] as String
      : null;

  static const _mensajeGenerico =
      'No pudimos completar la operación. Vuelve a intentarlo en un momento.';

  static Map<String, dynamic> _mapa(Object? datos) =>
      datos is Map ? Map<String, dynamic>.from(datos) : <String, dynamic>{};

  /// Mensaje en español para una respuesta de error del servidor. Un `422`
  /// trae el motivo escrito por el servidor; el resto, un texto fijo según
  /// el código, para no mostrar jerga técnica.
  static String mensajeDeServidor(int codigo, Object? cuerpo) {
    return switch (codigo) {
      401 => 'Tu sesión venció. Ingresa de nuevo.',
      403 => 'Esta cuenta no tiene permiso para hacer esto.',
      404 => 'No encontramos lo que buscas. Puede haber cambiado.',
      409 =>
        mensajeDeValidacion(cuerpo) ?? 'Esta operación ya se había registrado.',
      422 =>
        mensajeDeValidacion(cuerpo) ??
            'Revisa los datos y vuelve a intentarlo.',
      429 => 'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      >= 500 => 'Tuvimos un problema. Vuelve a intentarlo en un momento.',
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
