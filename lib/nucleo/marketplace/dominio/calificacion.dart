/// Calificación bidireccional: la escribe quien califica, en un registro
/// propio (un solo rol escritor por registro).
class CalificacionRecibida {
  const CalificacionRecibida({
    required this.servicioId,
    required this.autor,
    required this.puntaje,
    required this.fecha,
    this.comentario,
  });

  final String servicioId;
  final String autor;
  final int puntaje;
  final DateTime fecha;
  final String? comentario;
}

/// Etiquetas con las que el cliente describe al proveedor. Catálogo cerrado
/// de la política de calificación.
enum EtiquetaCalificacion {
  puntualidad('Puntualidad'),
  coberturaPareja('Cobertura pareja'),
  comunicacion('Comunicación'),
  cuidadoDelEntorno('Cuidado del entorno'),
  ordenEnElLote('Orden en el lote');

  const EtiquetaCalificacion(this.etiqueta);
  final String etiqueta;
}

/// La calificación que el cliente escribe sobre el proveedor de un servicio.
/// No se edita: una corrección es una moderación registrada.
class CalificacionEmitida {
  const CalificacionEmitida({
    required this.servicioId,
    required this.puntaje,
    required this.etiquetas,
    required this.fecha,
    this.comentario,
  });

  final String servicioId;

  /// De 1 a 5.
  final int puntaje;
  final Set<EtiquetaCalificacion> etiquetas;
  final DateTime fecha;
  final String? comentario;
}

/// Resumen de las calificaciones recibidas.
class ResumenCalificaciones {
  const ResumenCalificaciones({
    required this.promedio,
    required this.total,
    required this.recientes,
  });

  final double promedio;
  final int total;
  final List<CalificacionRecibida> recientes;
}
