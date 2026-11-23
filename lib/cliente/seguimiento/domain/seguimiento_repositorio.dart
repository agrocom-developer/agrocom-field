import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Seguimiento en vivo de un servicio activo.
abstract interface class SeguimientoRepositorio {
  Stream<SeguimientoVivo> observar(String servicioId);
}
