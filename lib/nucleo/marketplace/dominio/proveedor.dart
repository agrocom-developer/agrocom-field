import 'package:decimal/decimal.dart';

/// Quién ejecuta el servicio y cómo se relaciona con Agrocom.
enum TipoProveedor {
  propioAgrocom('Piloto de Agrocom'),
  independiente('Piloto independiente'),
  duenoDeDrones('Dueño de drones');

  const TipoProveedor(this.etiqueta);
  final String etiqueta;
}

enum PropiedadDron {
  agrocom('Agrocom'),
  tercero('Tercero');

  const PropiedadDron(this.etiqueta);
  final String etiqueta;
}

enum EstadoDron {
  disponible('Disponible'),
  enServicio('En servicio'),
  mantenimiento('En mantenimiento');

  const EstadoDron(this.etiqueta);
  final String etiqueta;
}

/// El dron es el «vehículo» del marketplace.
class Dron {
  const Dron({
    required this.id,
    required this.matricula,
    required this.modelo,
    required this.capacidadLitros,
    required this.estado,
    required this.propiedad,
    required this.ciclosBateria,
    required this.cicloMaximoBateria,
  });

  final String id;
  final String matricula;
  final String modelo;

  /// Capacidad del tanque, decimal exacto.
  final Decimal capacidadLitros;
  final EstadoDron estado;
  final PropiedadDron propiedad;
  final int ciclosBateria;
  final int cicloMaximoBateria;

  /// Fracción de vida útil de la batería ya consumida, de 0 a 1.
  double get desgasteBateria =>
      cicloMaximoBateria == 0 ? 0 : ciclosBateria / cicloMaximoBateria;
}

enum EstadoDocumento {
  vigente('Vigente'),
  porVencer('Por vencer'),
  enRevision('En revisión'),
  rechazado('Rechazado');

  const EstadoDocumento(this.etiqueta);
  final String etiqueta;
}

/// Licencia de piloto, matrícula del dron, seguro: los revisa el admin.
class DocumentoProveedor {
  const DocumentoProveedor({
    required this.nombre,
    required this.estado,
    this.vence,
  });

  final String nombre;
  final EstadoDocumento estado;
  final DateTime? vence;
}

/// Reseña de un cliente sobre un proveedor.
class Resena {
  const Resena({
    required this.autor,
    required this.puntaje,
    required this.fecha,
    this.comentario,
  });

  final String autor;

  /// De 1 a 5.
  final int puntaje;
  final DateTime fecha;
  final String? comentario;
}

class Proveedor {
  const Proveedor({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.calificacion,
    required this.serviciosCompletados,
    required this.zonas,
    this.drones = const [],
    this.documentos = const [],
    this.resenas = const [],
    this.auxiliares = const [],
    this.fotoRef,
  });

  final String id;
  final String nombre;
  final TipoProveedor tipo;

  /// Promedio de 1 a 5 (no es dinero ni superficie).
  final double calificacion;
  final int serviciosCompletados;
  final List<String> zonas;
  final List<Dron> drones;
  final List<DocumentoProveedor> documentos;
  final List<Resena> resenas;
  final List<String> auxiliares;

  /// Referencia del retrato: recurso empaquetado (`assets/…`) o URL. Sin
  /// ella se muestran las iniciales.
  final String? fotoRef;

  String get iniciales {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }
}

/// Hectáreas atendidas en un mes, para el gráfico del perfil.
class HectareasMensuales {
  const HectareasMensuales({required this.etiqueta, required this.hectareas});

  final String etiqueta;
  final Decimal hectareas;
}
