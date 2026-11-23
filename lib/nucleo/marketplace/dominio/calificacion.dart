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

/// Resumen de las calificaciones recibidas.
class ResumenCalificaciones {
  const ResumenCalificaciones({
    required this.promedio,
    required this.total,
    required this.recientes,
    this.porPuntaje = const {},
  });

  final double promedio;
  final int total;
  final List<CalificacionRecibida> recientes;

  /// Cuántas calificaciones hay de cada puntaje (clave de 1 a 5).
  final Map<int, int> porPuntaje;
}
