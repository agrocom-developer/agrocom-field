import 'package:decimal/decimal.dart';

import 'lote.dart';
import 'proveedor.dart';

enum EstadoServicio {
  buscandoProveedor('Buscando proveedor', activo: true),
  asignado('Proveedor asignado', activo: true),
  enEjecucion('En ejecución', activo: true),
  completado('Completado', activo: false),
  cancelado('Cancelado', activo: false);

  const EstadoServicio(this.etiqueta, {required this.activo});
  final String etiqueta;

  /// Un servicio activo es el que el cliente puede seguir en vivo.
  final bool activo;
}

/// Un servicio de fumigación solicitado por un cliente.
class Servicio {
  const Servicio({
    required this.id,
    required this.lote,
    required this.producto,
    required this.dosisLitrosPorHectarea,
    required this.hectareasDeclaradas,
    required this.hectareasCubiertas,
    required this.fechaDeseada,
    required this.estado,
    required this.precio,
    required this.solicitadoEn,
    this.proveedor,
    this.dron,
    this.puntajeDelCliente,
    this.puntajeDelProveedor,
    this.clienteNombre = 'Cliente',
    this.etaMinutos,
  });

  final String id;
  final Lote lote;
  final String producto;
  final Decimal dosisLitrosPorHectarea;
  final Decimal hectareasDeclaradas;
  final Decimal hectareasCubiertas;
  final DateTime fechaDeseada;
  final EstadoServicio estado;

  /// Monto en bolivianos, decimal exacto. Solo informativo: la app no cobra.
  final Decimal precio;
  final DateTime solicitadoEn;
  final Proveedor? proveedor;
  final Dron? dron;

  /// Calificación que el cliente dio al proveedor (1 a 5), si ya calificó.
  final int? puntajeDelCliente;

  /// Calificación que el proveedor dio al cliente (1 a 5).
  final int? puntajeDelProveedor;
  final String clienteNombre;
  final int? etaMinutos;

  /// Litros de caldo del servicio completo, decimal exacto.
  Decimal get litrosTotales => dosisLitrosPorHectarea * hectareasDeclaradas;

  /// Avance de 0 a 1 (proporción exacta convertida solo para dibujar).
  double get progreso {
    if (hectareasDeclaradas == Decimal.zero) return 0;
    final r = (hectareasCubiertas / hectareasDeclaradas).toDecimal(
      scaleOnInfinitePrecision: 4,
    );
    return r.toDouble().clamp(0.0, 1.0);
  }

  Servicio copiarCon({
    EstadoServicio? estado,
    Decimal? hectareasCubiertas,
    Proveedor? proveedor,
    Dron? dron,
    int? puntajeDelCliente,
    int? puntajeDelProveedor,
    int? etaMinutos,
  }) => Servicio(
    id: id,
    lote: lote,
    producto: producto,
    dosisLitrosPorHectarea: dosisLitrosPorHectarea,
    hectareasDeclaradas: hectareasDeclaradas,
    hectareasCubiertas: hectareasCubiertas ?? this.hectareasCubiertas,
    fechaDeseada: fechaDeseada,
    estado: estado ?? this.estado,
    precio: precio,
    solicitadoEn: solicitadoEn,
    proveedor: proveedor ?? this.proveedor,
    dron: dron ?? this.dron,
    puntajeDelCliente: puntajeDelCliente ?? this.puntajeDelCliente,
    puntajeDelProveedor: puntajeDelProveedor ?? this.puntajeDelProveedor,
    clienteNombre: clienteNombre,
    etaMinutos: etaMinutos ?? this.etaMinutos,
  );
}

/// Lo que el cliente declara al solicitar. `claveIdempotencia` nace en el
/// dispositivo para que un reintento no cree dos servicios (ADR 0009).
class SolicitudServicio {
  const SolicitudServicio({
    required this.lote,
    required this.producto,
    required this.dosisLitrosPorHectarea,
    required this.fechaDeseada,
    required this.claveIdempotencia,
  });

  final Lote lote;
  final String producto;
  final Decimal dosisLitrosPorHectarea;
  final DateTime fechaDeseada;
  final String claveIdempotencia;
}

/// Precio estimado antes de confirmar.
class EstimacionServicio {
  const EstimacionServicio({
    required this.precio,
    required this.litros,
    required this.precioPorHectarea,
  });

  final Decimal precio;
  final Decimal litros;
  final Decimal precioPorHectarea;
}
