import 'package:decimal/decimal.dart';

import 'solicitud.dart';

/// Solicitudes del cliente: las que negocia, las que se ejecutan y el
/// historial. Online-first: el repositorio de red lee de la API y, sin
/// conexión, muestra lo último que conoció (ADR 0009).
abstract interface class SolicitudesRepositorio {
  /// Todas las solicitudes (menos los borradores), de la más reciente a la
  /// más antigua. Vuelve a emitir cuando algo cambia o tras [refrescar].
  Stream<List<Solicitud>> observar();

  Future<Solicitud?> porId(String id);

  /// Vuelve a leer del servidor y avisa a quienes observan.
  Future<void> refrescar();

  /// Cambia el precio por hectárea mientras se negocia.
  Future<void> cambiarPrecio(String id, Decimal precioHa);

  /// Cancela con motivo; es gratuito y sin penalidad.
  Future<void> cancelar(String id, String motivo);

  /// Vuelve a abrir una solicitud expirada.
  Future<void> renovar(String id);
}
