import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Problemas que el cliente reporta sobre un servicio. Hay uno solo por
/// servicio y lo escribe el cliente; soporte lo responde por su lado.
///
/// Requiere red: el flavor cliente no tiene outbox. Sin conexión lanza
/// [SinConexion].
abstract interface class ProblemaRepositorio {
  /// El problema ya reportado en [servicioId], si existe.
  Future<ProblemaReportado?> delServicio(String servicioId);

  /// Registra el problema. La misma `claveIdempotencia` devuelve el mismo
  /// caso; si el servicio ya tiene uno, devuelve ese.
  Future<ProblemaReportado> reportar(ReporteProblema reporte);
}
