import 'package:decimal/decimal.dart';

import '../../demo/almacen_demo_auxiliar.dart';
import '../domain/mezcla_repositorio.dart';

class MezclaDemo implements MezclaRepositorio {
  MezclaDemo(this._almacen);

  final AlmacenDemoAuxiliar _almacen;

  @override
  Stream<List<RegistroMezcla>> observar() => _almacen.observar();

  @override
  Future<void> registrar({
    required String producto,
    required Decimal litros,
  }) async => _almacen.agregar(producto, litros);
}
