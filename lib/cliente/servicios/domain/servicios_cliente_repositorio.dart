import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Servicios del cliente: en curso e historial. Online-first: el repositorio
/// real lee de la API con caché de lectura; sin red muestra lo último
/// conocido (ADR 0009). La pantalla solo conoce esta interfaz.
abstract interface class ServiciosClienteRepositorio {
  /// Todos los servicios del cliente, del más reciente al más antiguo.
  /// Emite de nuevo cuando algo cambia (solicitud nueva, calificación).
  Stream<List<Servicio>> observar();

  Future<Servicio?> porId(String id);
}
