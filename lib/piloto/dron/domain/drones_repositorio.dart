import '../../../nucleo/marketplace/dominio/dominio.dart';

abstract interface class DronesRepositorio {
  Stream<List<Dron>> observar();
}
