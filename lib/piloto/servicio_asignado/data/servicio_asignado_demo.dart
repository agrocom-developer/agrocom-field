import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../domain/servicio_asignado_repositorio.dart';

class ServicioAsignadoDemo implements ServicioAsignadoRepositorio {
  ServicioAsignadoDemo(this._almacen);

  final AlmacenDemoProveedor _almacen;

  @override
  Stream<List<Servicio>> observar() => _almacen.observarAsignados();
}
