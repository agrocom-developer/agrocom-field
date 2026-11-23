import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_auxiliar.dart';
import '../domain/servicio_asignado_auxiliar_repositorio.dart';

class ServicioAsignadoAuxiliarDemo
    implements ServicioAsignadoAuxiliarRepositorio {
  ServicioAsignadoAuxiliarDemo(this._almacen);

  final AlmacenDemoAuxiliar _almacen;

  @override
  Stream<Servicio?> observar() => Stream.value(_almacen.datos.servicios.first);
}
