/// Si el dispositivo tiene red. La bandeja lo consulta porque aceptar y
/// rechazar una oferta son las únicas acciones del proveedor que la exigen
/// (ADR 0009): sin red los botones lo dicen y no se intenta la respuesta.
abstract interface class EstadoRed {
  /// Emite el estado actual al suscribirse y cada cambio después.
  Stream<bool> observar();
}
