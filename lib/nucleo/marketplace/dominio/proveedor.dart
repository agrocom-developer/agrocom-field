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

/// Estado de aprobación de un proveedor, un piloto o un dron.
/// Solo un administrador lo cambia desde el panel web.
enum EstadoAprobacion {
  pendiente('En revisión'),
  aprobado('Aprobado'),
  suspendido('Suspendido'),
  rechazado('Rechazado');

  const EstadoAprobacion(this.etiqueta);
  final String etiqueta;

  /// Solo un sujeto aprobado opera en el marketplace.
  bool get habilitado => this == aprobado;
}

/// Estado de revisión de una foto del dron.
enum EstadoFotoDron {
  enRevision('En revisión'),
  aprobada('Aprobada'),
  rechazada('Rechazada');

  const EstadoFotoDron(this.etiqueta);
  final String etiqueta;
}

/// Una foto del dron que un administrador aprueba o rechaza con motivo.
class FotoDelDron {
  const FotoDelDron({
    required this.id,
    required this.tipo,
    required this.estado,
    this.motivo,
  });

  final int id;

  /// `frontal`, `lateral`, `placa_serie` u `otra`.
  final String tipo;
  final EstadoFotoDron estado;
  final String? motivo;
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
    this.aprobacion = EstadoAprobacion.aprobado,
    this.fotos = const [],
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

  /// Ningún dron vuela sin aprobación de un administrador.
  final EstadoAprobacion aprobacion;

  /// Las fotos que subió el proveedor, con su estado de revisión.
  final List<FotoDelDron> fotos;

  /// Fracción de vida útil de la batería ya consumida, de 0 a 1.
  double get desgasteBateria => cicloMaximoBateria == 0
      ? 0
      : (ciclosBateria / cicloMaximoBateria).clamp(0, 1).toDouble();

  /// Ciclos que le quedan a la batería antes del recambio.
  int get ciclosRestantes => ciclosBateria >= cicloMaximoBateria
      ? 0
      : cicloMaximoBateria - ciclosBateria;

  /// A partir de tres cuartos de vida útil conviene planificar el recambio.
  bool get bateriaPorAgotarse => desgasteBateria >= 0.75;
}

enum EstadoDocumento {
  vigente('Vigente'),
  porVencer('Por vencer'),
  enRevision('En revisión'),
  rechazado('Rechazado'),
  vencido('Vencido');

  const EstadoDocumento(this.etiqueta);
  final String etiqueta;

  /// El documento exige que el proveedor haga algo (renovar o volver a subir).
  bool get requiereAccion =>
      this == porVencer || this == rechazado || this == vencido;
}

/// Licencia de piloto, matrícula del dron, seguro: los revisa el admin.
class DocumentoProveedor {
  const DocumentoProveedor({
    required this.nombre,
    required this.estado,
    this.vence,
    this.motivoRechazo,
  });

  final String nombre;
  final EstadoDocumento estado;
  final DateTime? vence;

  /// Lo que escribió el administrador al rechazarlo.
  final String? motivoRechazo;
}

/// Métricas operativas del proveedor. Los porcentajes son enteros de 0 a 100
/// calculados por el servidor; las hectáreas, decimal exacto.
class MetricasProveedor {
  const MetricasProveedor({
    required this.serviciosCompletados,
    required this.hectareasAtendidas,
    required this.tasaAceptacion,
    required this.tasaCancelacion,
  });

  final int serviciosCompletados;
  final Decimal hectareasAtendidas;
  final int tasaAceptacion;
  final int tasaCancelacion;
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
    this.aprobacion = EstadoAprobacion.aprobado,
    this.motivoAprobacion,
    this.fotoRef,
    this.fotoUrl,
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

  /// Ningún proveedor opera sin aprobación de un administrador.
  final EstadoAprobacion aprobacion;

  /// Motivo que dio el administrador al suspender o rechazar.
  final String? motivoAprobacion;

  /// Foto de perfil: URL firmada y de corta vida (15 minutos) que el
  /// servidor entrega con la sesión; `null` si la cuenta no tiene foto.
  final String? fotoUrl;

  /// Documentos que el proveedor tiene que renovar o volver a subir.
  List<DocumentoProveedor> get documentosConAccion => [
    for (final d in documentos)
      if (d.estado.requiereAccion) d,
  ];

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
