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
  const OperacionRechazada(this.mensaje, {this.codigo, this.motivo});

  final String mensaje;

  /// Código HTTP de la respuesta, si la hubo.
  final int? codigo;

  /// Código de negocio del servidor (`oferta_no_vigente`,
  /// `solicitud_ya_adjudicada`...), si lo trae.
  final String? motivo;

  @override
  String toString() => 'OperacionRechazada($mensaje)';
}
