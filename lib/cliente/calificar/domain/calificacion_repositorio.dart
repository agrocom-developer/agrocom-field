import '../../../nucleo/marketplace/dominio/dominio.dart';

/// El cliente escribe la calificación del proveedor en un registro propio;
/// las que recibe de los proveedores solo las lee.
///
/// Requiere red: el flavor cliente no tiene outbox. Sin conexión lanza
/// [SinConexion].
abstract interface class CalificacionRepositorio {
  /// Registra la calificación. Es única por servicio: repetir la llamada no
  /// la cambia.
  Future<void> calificarProveedor({
    required String servicioId,
    required int puntaje,
    Set<EtiquetaCalificacion> etiquetas = const {},
    String? comentario,
  });

  /// La calificación que el cliente dio en [servicioId], si existe.
  Future<CalificacionEmitida?> emitida(String servicioId);

  /// Lo que los proveedores calificaron del cliente.
  Future<ResumenCalificaciones> recibidas();
}
