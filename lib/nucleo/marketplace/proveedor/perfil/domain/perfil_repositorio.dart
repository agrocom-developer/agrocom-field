import '../../../dominio/dominio.dart';

abstract interface class PerfilRepositorio {
  /// El proveedor con su estado de aprobación, documentos y auxiliares.
  Future<Proveedor> perfil();

  /// Hectáreas atendidas por mes (decimal exacto), para el gráfico.
  Future<List<HectareasMensuales>> hectareasPorMes();

  /// Servicios ya ejecutados, del más reciente al más antiguo.
  Future<List<Servicio>> historial();

  /// Servicios, hectáreas y tasas de aceptación y cancelación.
  Future<MetricasProveedor> metricas();

  /// Calificaciones que los clientes dejaron sobre el proveedor.
  Future<ResumenCalificaciones> calificaciones();
}
