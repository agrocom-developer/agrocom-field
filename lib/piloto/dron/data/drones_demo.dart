import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_piloto.dart';
import '../domain/drones_repositorio.dart';

class DronesDemo implements DronesRepositorio {
  DronesDemo(this._almacen);

  final AlmacenDemoPiloto _almacen;

  @override
  Stream<List<Dron>> observar() => Stream.value(_almacen.piloto.drones);
}
