import '../../demo/almacen_demo_cliente.dart';
import '../domain/cuenta_repositorio.dart';
import '../../../nucleo/marketplace/demo/datos_demo.dart';

class CuentaDemo implements CuentaRepositorio {
  CuentaDemo(this._almacen);

  final AlmacenDemoCliente _almacen;

  @override
  Future<CuentaCliente> cuenta() async => CuentaCliente(
    nombre: DatosDemo.clienteNombre,
    empresa: DatosDemo.clienteEmpresa,
    telefono: '+591 7712 3456',
    correo: 'hugo.antelo@lostajibos.example',
    serviciosTotales: _almacen.servicios.length,
  );
}
