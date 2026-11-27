/// Quién envía el aviso: el sistema de Agrocom o la otra parte del servicio
/// (el piloto para el cliente, el cliente para el piloto).
sealed class OrigenNotificacion {
  const OrigenNotificacion();
}

/// Aviso automático de Agrocom (aprobaciones, ofertas, cambios de estado).
final class OrigenSistema extends OrigenNotificacion {
  const OrigenSistema();
}

/// Mensaje de una persona; [nombre] sale en el título y las iniciales en el
/// avatar.
final class OrigenPersona extends OrigenNotificacion {
  const OrigenPersona(this.nombre);

  final String nombre;
}

/// A qué recurso lleva el aviso al abrirlo (`recurso_tipo` y `recurso_id`
/// del contrato), p. ej. `solicitud` 42.
class DestinoNotificacion {
  const DestinoNotificacion(this.tipo, this.id);

  final String tipo;
  final int id;
}

class Notificacion {
  const Notificacion({
    required this.id,
    required this.origen,
    required this.titulo,
    required this.fecha,
    this.cuerpo = '',
    this.leida = false,
    this.destino,
  });

  final int id;
  final OrigenNotificacion origen;
  final String titulo;

  /// Texto del mensaje; vacío en los avisos del sistema que solo traen título.
  final String cuerpo;
  final DateTime fecha;
  final bool leida;
  final DestinoNotificacion? destino;

  bool get esMensaje => origen is OrigenPersona;

  Notificacion comoLeida() => Notificacion(
    id: id,
    origen: origen,
    titulo: titulo,
    cuerpo: cuerpo,
    fecha: fecha,
    leida: true,
    destino: destino,
  );
}
