import '../../../nucleo/marketplace/dominio/dominio.dart';

abstract interface class PerfilRepositorio {
  Future<Proveedor> perfil();

  /// Hectáreas atendidas por mes (decimal exacto), para el gráfico.
  Future<List<HectareasMensuales>> hectareasPorMes();

  /// Servicios ya ejecutados, del más reciente al más antiguo.
  Future<List<Servicio>> historial();
}
