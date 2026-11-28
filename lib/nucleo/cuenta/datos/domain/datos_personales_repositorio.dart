import 'datos_personales.dart';

/// Datos personales de la cuenta: una sola edición libre tras el registro y,
/// después, solicitudes de cambio a atención al cliente (online-first).
abstract interface class DatosPersonalesRepositorio {
  /// `false` cuando el servidor todavía no ofrece esta función: la app no
  /// muestra la entrada en Ajustes.
  bool get disponible;

  Future<EstadoDatosPersonales> cargar();

  /// Guarda [datos] y gasta la única edición. El servidor responde `409` si
  /// ya se usó; llega como `OperacionRechazada` con `codigo: 409`.
  Future<EstadoDatosPersonales> editarUnaVez(DatosPersonales datos);

  /// Pide a atención al cliente que corrija un dato, con el [motivo] escrito.
  /// Un administrador la revisa; los datos no cambian desde la app.
  Future<SolicitudCambio> solicitarCambio(String motivo);
}
