import '../../../dominio/dominio.dart';
import '../../demo/almacen_demo_proveedor.dart';
import '../domain/perfil_repositorio.dart';

class PerfilDemo implements PerfilRepositorio {
  PerfilDemo(this._almacen);

  final AlmacenDemoProveedor _almacen;

  @override
  Future<Proveedor> perfil() async => _almacen.piloto;

  @override
  Future<List<HectareasMensuales>> hectareasPorMes() async =>
      _almacen.datos.hectareasMensuales;

  @override
  Future<List<Servicio>> historial() async => [
    for (final s in _almacen.datos.servicios)
      if (s.estado == EstadoServicio.completado &&
          s.proveedor?.id == _almacen.piloto.id)
        s,
  ];

  @override
  Future<MetricasProveedor> metricas() async => _almacen.datos.metricasPiloto;

  @override
  Future<ResumenCalificaciones> calificaciones() async =>
      _almacen.datos.calificacionesDelPiloto;
}
