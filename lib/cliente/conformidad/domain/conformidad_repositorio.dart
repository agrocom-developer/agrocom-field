import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Evidencias y acta de conformidad de un servicio. El cliente las lee y
/// escribe una sola cosa: su firma.
///
/// Requiere red: el flavor cliente no tiene outbox. Sin conexión lanza
/// [SinConexion].
abstract interface class ConformidadRepositorio {
  /// Acta (si el servidor ya validó la sesión) y evidencias de [servicioId].
  Future<ExpedienteServicio> expediente(String servicioId);

  /// Firma el acta. [claveIdempotencia] nace al abrir la pantalla y se
  /// reutiliza en cada reintento: firmar dos veces devuelve la misma acta.
  Future<ActaConformidad> firmar({
    required String servicioId,
    required String claveIdempotencia,
  });
}
