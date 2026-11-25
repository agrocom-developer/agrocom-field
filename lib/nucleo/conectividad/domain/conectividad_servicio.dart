/// Estado de la red visto por la interfaz: hay red o no. No distingue el tipo
/// de conexión; la UI solo necesita saber si puede pedir cosas al servidor.
enum EstadoRed { conRed, sinRed }

/// Fuente del estado de la red para la UI (ADR 0010: interfaz en el dominio,
/// implementación real y falsa). El disparador de sync tiene su propio uso de
/// `connectivity_plus`; esto es solo para pintar avisos.
abstract interface class ConectividadServicio {
  /// Estado actual, consultado una vez.
  Future<EstadoRed> consultar();

  /// Cambios posteriores. No repite el estado actual: ese lo da [consultar].
  Stream<EstadoRed> get cambios;
}
