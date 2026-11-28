/// Puerto de las notificaciones remotas (push). Hoy no hay proveedor: el dueño
/// activará Firebase Messaging con la versión beta (ADR 0026, punto 5), y
/// entonces basta con una implementación de esta interfaz. Mientras tanto la
/// app usa [NotificacionesRemotasNulas] y los avisos se leen de
/// `GET /api/notificaciones`.
enum EstadoPushRemoto {
  /// No hay proveedor de push configurado en esta compilación.
  noConfigurado,

  /// Hay proveedor, pero la persona no concedió el permiso de avisos.
  sinPermiso,

  /// Listo para recibir.
  activo,
}

/// Un aviso recibido del servidor. Solo lleva lo necesario para abrir la
/// pantalla correspondiente; el contenido sensible se lee del servidor al
/// abrirlo.
class AvisoRemoto {
  const AvisoRemoto({
    required this.titulo,
    required this.cuerpo,
    this.solicitudId,
  });

  final String titulo;
  final String cuerpo;
  final int? solicitudId;
}

abstract interface class NotificacionesRemotas {
  Future<EstadoPushRemoto> estado();

  /// Token del aparato para `/api/dispositivos`, o `null` si no hay proveedor.
  /// Nunca se registra en logs ni se guarda fuera del almacenamiento seguro.
  Future<String?> obtenerToken();

  /// Avisos que llegan con la app abierta o al abrirla desde un aviso.
  Stream<AvisoRemoto> get avisos;
}

/// Implementación nula: sin proveedor, sin token y sin avisos.
class NotificacionesRemotasNulas implements NotificacionesRemotas {
  const NotificacionesRemotasNulas();

  @override
  Future<EstadoPushRemoto> estado() async => EstadoPushRemoto.noConfigurado;

  @override
  Future<String?> obtenerToken() async => null;

  @override
  Stream<AvisoRemoto> get avisos => const Stream.empty();
}
