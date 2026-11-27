import 'notificacion.dart';

/// Los avisos y mensajes recibidos por la cuenta. Online-first: se lee del
/// servidor al abrir la bandeja. Lanza `FallaMarketplace` (`SinConexion` u
/// `OperacionRechazada`).
abstract interface class BandejaRepositorio {
  /// Los más recientes, los no leídos primero.
  Future<List<Notificacion>> listar();

  /// Marca un aviso como leído; es idempotente.
  Future<void> marcarLeida(int id);

  /// Marca como leídos todos los avisos pendientes.
  Future<void> marcarTodasLeidas();
}
