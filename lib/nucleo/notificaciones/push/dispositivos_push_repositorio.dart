import '../../api/marketplace_http.dart';
import '../../marketplace/dominio/falla.dart';
import 'token_push_store.dart';

/// Plataforma del aparato, tal como la espera el contrato.
enum PlataformaPush { android, ios }

/// Registro del token de push del aparato en el servidor.
///
/// El token nunca se escribe en un log ni en un mensaje de error: ni acá ni
/// en quien llama. Se guarda solo en [TokenPushStore] (almacenamiento seguro).
abstract interface class DispositivosPushRepositorio {
  /// Registra [token] para la cuenta de la sesión y lo guarda en el
  /// almacenamiento seguro. Idempotente: repetirlo no duplica nada.
  Future<void> registrar(String token, PlataformaPush plataforma);

  /// Retira el token guardado, al cerrar sesión. Debe llamarse **antes** de
  /// borrar el token de sesión (la baja va autenticada). Un `404` (el
  /// servidor ya no lo tenía) se toma como hecho; sin red, el token queda
  /// guardado para reintentar y se lanza [SinConexion].
  Future<void> retirar();
}

class DispositivosPushRed implements DispositivosPushRepositorio {
  DispositivosPushRed(this._http, this._almacen);

  final MarketplaceHttp _http;
  final TokenPushStore _almacen;

  @override
  Future<void> registrar(String token, PlataformaPush plataforma) async {
    await _http.enviar(
      '/api/dispositivos',
      datos: {'token': token, 'plataforma': plataforma.name},
    );
    await _almacen.guardar(token);
  }

  @override
  Future<void> retirar() async {
    final token = await _almacen.leer();
    if (token == null) return;
    try {
      await _http.borrar('/api/dispositivos/${Uri.encodeComponent(token)}');
    } on OperacionRechazada catch (e) {
      // 404: el token no existe o es de otra cuenta; no hay nada que retirar.
      if (e.codigo != 404) rethrow;
    }
    await _almacen.borrar();
  }
}

/// En memoria: guarda el token como el real pero no llama a ningún servidor.
class DispositivosPushDemo implements DispositivosPushRepositorio {
  DispositivosPushDemo(this._almacen);

  final TokenPushStore _almacen;

  @override
  Future<void> registrar(String token, PlataformaPush plataforma) =>
      _almacen.guardar(token);

  @override
  Future<void> retirar() => _almacen.borrar();
}
