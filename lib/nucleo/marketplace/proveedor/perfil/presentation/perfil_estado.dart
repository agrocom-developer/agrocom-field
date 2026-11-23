import '../../../dominio/dominio.dart';

sealed class PerfilEstado {
  const PerfilEstado();
}

final class PerfilCargando extends PerfilEstado {
  const PerfilCargando();
}

final class PerfilError extends PerfilEstado {
  const PerfilError();
}

final class PerfilListo extends PerfilEstado {
  const PerfilListo({
    required this.proveedor,
    required this.metricas,
    required this.calificaciones,
    required this.hectareasPorMes,
  });

  final Proveedor proveedor;
  final MetricasProveedor metricas;
  final ResumenCalificaciones calificaciones;
  final List<HectareasMensuales> hectareasPorMes;
}
