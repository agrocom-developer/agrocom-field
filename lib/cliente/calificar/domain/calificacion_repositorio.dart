import '../../../nucleo/marketplace/dominio/dominio.dart';

/// El cliente escribe la calificación del proveedor en un registro propio;
/// las que recibe de los proveedores solo las lee.
abstract interface class CalificacionRepositorio {
  Future<void> calificarProveedor({
    required String servicioId,
    required int puntaje,
    String? comentario,
  });

  /// Lo que los proveedores calificaron del cliente.
  Future<ResumenCalificaciones> recibidas();
}
