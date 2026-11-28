/// Datos personales de la cuenta (cliente o proveedor). [empresa] y
/// [documento] solo existen cuando el rol o el tipo de persona los pide;
/// la pantalla muestra solo los que vienen.
class DatosPersonales {
  const DatosPersonales({
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.empresa,
    this.documento,
  });

  final String nombre;
  final String correo;
  final String telefono;
  final String? empresa;
  final String? documento;

  DatosPersonales copiarCon({
    String? nombre,
    String? correo,
    String? telefono,
    String? empresa,
    String? documento,
  }) => DatosPersonales(
    nombre: nombre ?? this.nombre,
    correo: correo ?? this.correo,
    telefono: telefono ?? this.telefono,
    empresa: empresa ?? this.empresa,
    documento: documento ?? this.documento,
  );
}

/// Estado de una solicitud de cambio a atención al cliente.
enum EstadoSolicitudCambio { pendiente, enRevision, resuelta }

class SolicitudCambio {
  const SolicitudCambio({
    required this.motivo,
    required this.estado,
    required this.creada,
  });

  final String motivo;
  final EstadoSolicitudCambio estado;
  final DateTime creada;

  /// Sigue sin respuesta: no se puede enviar otra encima.
  bool get abierta => estado != EstadoSolicitudCambio.resuelta;
}

/// Lo que la pantalla necesita para decidir qué mostrar. Quién puede editar
/// lo decide el servidor: la app solo lee [puedeEditar].
class EstadoDatosPersonales {
  const EstadoDatosPersonales({
    required this.datos,
    required this.puedeEditar,
    this.solicitud,
  });

  final DatosPersonales datos;

  /// `true` mientras la persona no usó su única edición.
  final bool puedeEditar;

  /// La solicitud de cambio más reciente, si hay una.
  final SolicitudCambio? solicitud;

  bool get solicitudAbierta => solicitud?.abierta ?? false;
}
