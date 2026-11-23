import '../../demo/almacen_demo_proveedor.dart';
import '../domain/estado_red.dart';

class EstadoRedDemo implements EstadoRed {
  EstadoRedDemo(this._almacen);

  final AlmacenDemoProveedor _almacen;

  @override
  Stream<bool> observar() => _almacen.observarRed();
}
