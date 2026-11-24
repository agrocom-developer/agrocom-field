/// Fallas que un repositorio online-first del marketplace puede lanzar. Las
/// pantallas distinguen «sin conexión» (se resuelve reintentando con señal)
/// de cualquier otro error.
sealed class FallaMarketplace implements Exception {
  const FallaMarketplace();
}

/// El dispositivo no tiene red o el servidor no respondió.
final class SinConexion extends FallaMarketplace {
  const SinConexion();

  @override
  String toString() => 'SinConexion';
}

/// El servidor rechazó la operación con un mensaje para el usuario.
final class OperacionRechazada extends FallaMarketplace {
  const OperacionRechazada(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'OperacionRechazada($mensaje)';
}
