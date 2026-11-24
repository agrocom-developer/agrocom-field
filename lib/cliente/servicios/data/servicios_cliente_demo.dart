import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/servicios_cliente_repositorio.dart';

class ServiciosClienteDemo implements ServiciosClienteRepositorio {
  ServiciosClienteDemo(this._almacen);

  final AlmacenDemoCliente _almacen;

  @override
  Stream<List<Servicio>> observar() =>
      _almacen.sinRed ? Stream.error(const SinConexion()) : _almacen.observar();

  @override
  Future<Servicio?> porId(String id) async => _almacen.porId(id);
}
