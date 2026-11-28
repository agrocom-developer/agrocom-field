/// Los permisos de tiempo de ejecución que usa la app. Cada uno se pide en
/// el momento de la actividad que lo necesita, nunca al arrancar.
enum PermisoApp {
  /// Tomar una foto (perfil, terreno, avance, documentos, chat).
  camara,

  /// Elegir una foto de la galería. Siempre `noRequerido`: se usa el
  /// selector de fotos del sistema (PHPicker en iOS, Photo Picker o
  /// `ACTION_GET_CONTENT` en Android), que solo entrega lo que la persona
  /// elige y no necesita permiso de almacenamiento en ninguna versión.
  fotos,

  /// Ubicación mientras se usa la app (aproximada o precisa, la elige la
  /// persona en Android 12+).
  ubicacion,

  /// Avisos de solicitudes nuevas (Android 13+ e iOS).
  notificaciones,
}

/// Cómo está un permiso en este momento.
enum EstadoPermiso {
  /// Se puede usar.
  concedido,

  /// No se ha pedido o se negó; se puede volver a pedir.
  denegado,

  /// Se negó y el sistema ya no muestra el aviso: solo se activa en los
  /// ajustes del teléfono.
  denegadoParaSiempre,

  /// El sistema lo bloquea (control parental, perfil de empresa).
  restringido,

  /// En esta plataforma o versión no hace falta pedirlo.
  noRequerido;

  bool get permite => this == concedido || this == noRequerido;
}
