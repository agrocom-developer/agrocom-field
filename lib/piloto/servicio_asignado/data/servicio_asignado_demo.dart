import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_piloto.dart';
import '../domain/servicio_asignado_repositorio.dart';

class ServicioAsignadoDemo implements ServicioAsignadoRepositorio {
  ServicioAsignadoDemo(this._almacen);

  final AlmacenDemoPiloto _almacen;

  @override
  Stream<List<Servicio>> observar() => _almacen.observarAsignados();
}
