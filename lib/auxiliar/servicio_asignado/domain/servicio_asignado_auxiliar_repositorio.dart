import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Servicio al que el auxiliar acompaña, bajado a `drift` al aceptarlo el
/// piloto. La demo lo sirve desde memoria.
abstract interface class ServicioAsignadoAuxiliarRepositorio {
  Stream<Servicio?> observar();
}
