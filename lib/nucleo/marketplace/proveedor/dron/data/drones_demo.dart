import '../../../dominio/dominio.dart';
import '../../demo/almacen_demo_proveedor.dart';
import '../domain/drones_repositorio.dart';

class DronesDemo implements DronesRepositorio {
  DronesDemo(this._almacen);

  final AlmacenDemoProveedor _almacen;

  @override
  Stream<List<Dron>> observar() => Stream.value(_almacen.piloto.drones);
}
