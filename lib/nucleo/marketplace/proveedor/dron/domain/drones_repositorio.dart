import '../../../dominio/dominio.dart';

abstract interface class DronesRepositorio {
  /// Los drones del proveedor, con su estado y los ciclos de batería.
  Stream<List<Dron>> observar();
}
