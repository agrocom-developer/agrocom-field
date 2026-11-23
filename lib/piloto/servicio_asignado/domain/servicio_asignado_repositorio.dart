import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Servicios que el piloto aceptó, el vigente primero. En el repositorio
/// real se leen de `drift` (sin red en el lote); la demo los sirve desde
/// memoria.
abstract interface class ServicioAsignadoRepositorio {
  Stream<List<Servicio>> observar();
}
