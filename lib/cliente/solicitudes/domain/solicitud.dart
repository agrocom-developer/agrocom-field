import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Estado de una solicitud tal como lo ve el cliente (ADR 0016). El servidor
/// decide cada transición; la app solo lo muestra.
enum EstadoSolicitud {
  borrador('Borrador', 'Todavía no está publicada.'),
  abierta('Buscando piloto', 'Los pilotos ya pueden ver tu solicitud.'),
  conOfertas('Buscando piloto', 'Ya tienes ofertas para comparar.'),
  adjudicada('Piloto elegido', 'Acuerden en persona cómo trabajar el lote.'),
  enEjecucion('En ejecución', 'El piloto está trabajando en tu lote.'),
  finalizada('Finalizada', 'El piloto terminó. Revisa el resultado.'),
  calificada('Calificada', 'Gracias por calificar el servicio.'),
  disputada('En disputa', 'Soporte está revisando el caso.'),
  expirada('Expirada', 'Nadie la tomó a tiempo. Puedes volver a abrirla.'),
  cancelada('Cancelada', 'La solicitud se canceló.');

  const EstadoSolicitud(this.etiqueta, this.apoyo);
  final String etiqueta;
  final String apoyo;

  /// Se negocia: el cliente puede cambiar el precio o cancelar.
  bool get negociando => this == abierta || this == conOfertas;

  /// Sigue viva: no terminó ni se cerró.
  bool get activa => switch (this) {
    borrador ||
    abierta ||
    conOfertas ||
    adjudicada ||
    enEjecucion ||
    finalizada ||
    disputada => true,
    calificada || expirada || cancelada => false,
  };

  /// Ya hay piloto elegido: aparecen el chat y el seguimiento.
  bool get conPiloto => switch (this) {
    adjudicada || enEjecucion || finalizada || calificada || disputada => true,
    _ => false,
  };

  /// El servicio terminó y se muestra el precio final.
  bool get terminada =>
      this == finalizada || this == calificada || this == disputada;

  static EstadoSolicitud desdeApi(String? valor) => switch (valor) {
    'borrador' => borrador,
    'abierta' => abierta,
    'con_ofertas' => conOfertas,
    'adjudicada' => adjudicada,
    'en_ejecucion' => enEjecucion,
    'finalizada' => finalizada,
    'calificada' => calificada,
    'disputada' => disputada,
    'expirada' => expirada,
    'cancelada' => cancelada,
    _ => abierta,
  };
}

/// Un cambio de estado de la solicitud, del historial del servidor.
class CambioEstado {
  const CambioEstado({required this.estado, required this.momento});

  final EstadoSolicitud estado;
  final DateTime momento;
}

/// Solicitud de fumigación del cliente: su propiedad, lo que quiere aplicar y
/// el precio por hectárea que propone. Importes y hectáreas son [Decimal]
/// (ADR 0002).
class Solicitud {
  const Solicitud({
    required this.id,
    required this.lote,
    required this.hectareas,
    required this.cultivo,
    required this.producto,
    required this.ventanaDesde,
    required this.ventanaHasta,
    required this.precioHaPropuesto,
    required this.estado,
    this.tipoAplicacion = 'otro',
    this.observaciones,
    this.accesos,
    this.precioHaAcordado,
    this.montoEstimado,
    this.hectareasEjecutadas,
    this.porcentajeAvance,
    this.montoFinal,
    this.proveedorId,
    this.ofertaAdjudicadaId,
    this.venceEn,
    this.publicadaEn,
    this.motivoCancelacion,
    this.historial = const [],
    this.puntajeDelCliente,
    this.nombreProveedor,
    this.ofertasVigentes,
  });

  final String id;
  final Lote lote;

  /// Superficie a fumigar (puede ser menor a la del lote).
  final Decimal hectareas;
  final String cultivo;
  final String producto;
  final String tipoAplicacion;
  final DateTime ventanaDesde;
  final DateTime ventanaHasta;
  final String? observaciones;

  /// Cómo se llega al lote (referencias de acceso del terreno).
  final String? accesos;

  /// Lo que propone el cliente, por hectárea.
  final Decimal precioHaPropuesto;

  /// Lo que quedó acordado al adjudicar; nulo mientras se negocia.
  final Decimal? precioHaAcordado;
  final Decimal? montoEstimado;
  final Decimal? hectareasEjecutadas;

  /// De 0 a 100, calculado por el servidor.
  final Decimal? porcentajeAvance;

  /// Hectáreas ejecutadas por precio acordado, congelado al finalizar.
  final Decimal? montoFinal;
  final EstadoSolicitud estado;
  final String? proveedorId;
  final String? ofertaAdjudicadaId;
  final DateTime? venceEn;
  final DateTime? publicadaEn;
  final String? motivoCancelacion;
  final List<CambioEstado> historial;

  /// Estrellas que el cliente dio al proveedor, si ya calificó.
  final int? puntajeDelCliente;

  /// Nombre del piloto o proveedor adjudicado, cuando se conoce.
  final String? nombreProveedor;

  /// Cuántas ofertas vigentes tiene; solo lo informa la lista de ofertas.
  final int? ofertasVigentes;

  /// Precio por hectárea que rige hoy: el acordado, o el propuesto.
  Decimal get precioHaVigente => precioHaAcordado ?? precioHaPropuesto;

  /// Total estimado con el precio que rige.
  Decimal get totalEstimado => montoEstimado ?? hectareas * precioHaVigente;

  /// Lo que se muestra a pagar: el final si ya se congeló; si no, el
  /// estimado.
  Decimal get totalAPagar => montoFinal ?? totalEstimado;

  /// Avance de 0 a 1, solo para dibujar la barra.
  double get progreso {
    final p = porcentajeAvance;
    if (p == null) return 0;
    return (p.toDouble() / 100).clamp(0.0, 1.0);
  }

  DateTime? momentoDe(EstadoSolicitud e) {
    for (final c in historial.reversed) {
      if (c.estado == e) return c.momento;
    }
    return null;
  }

  Solicitud copiarCon({
    EstadoSolicitud? estado,
    Decimal? precioHaPropuesto,
    int? puntajeDelCliente,
    String? nombreProveedor,
    int? ofertasVigentes,
  }) => Solicitud(
    id: id,
    lote: lote,
    hectareas: hectareas,
    cultivo: cultivo,
    producto: producto,
    tipoAplicacion: tipoAplicacion,
    ventanaDesde: ventanaDesde,
    ventanaHasta: ventanaHasta,
    observaciones: observaciones,
    accesos: accesos,
    precioHaPropuesto: precioHaPropuesto ?? this.precioHaPropuesto,
    precioHaAcordado: precioHaAcordado,
    montoEstimado: montoEstimado,
    hectareasEjecutadas: hectareasEjecutadas,
    porcentajeAvance: porcentajeAvance,
    montoFinal: montoFinal,
    estado: estado ?? this.estado,
    proveedorId: proveedorId,
    ofertaAdjudicadaId: ofertaAdjudicadaId,
    venceEn: venceEn,
    publicadaEn: publicadaEn,
    motivoCancelacion: motivoCancelacion,
    historial: historial,
    puntajeDelCliente: puntajeDelCliente ?? this.puntajeDelCliente,
    nombreProveedor: nombreProveedor ?? this.nombreProveedor,
    ofertasVigentes: ofertasVigentes ?? this.ofertasVigentes,
  );
}

enum EstadoHito { hecho, actual, pendiente }

/// Un punto de la línea de tiempo de la solicitud.
class HitoSolicitud {
  const HitoSolicitud({
    required this.clave,
    required this.estado,
    required this.titulo,
    required this.detalle,
    this.momento,
  });

  final String clave;
  final EstadoHito estado;
  final String titulo;
  final String detalle;
  final DateTime? momento;
}

/// Arma la línea de tiempo de una solicitud: publicada, ofertas, piloto
/// elegido, ejecución, resultado y calificación. Una solicitud cancelada o
/// expirada se detiene donde quedó: nada queda «en curso».
List<HitoSolicitud> lineaDeTiempo(Solicitud s) {
  // Índice del punto en curso y cuántos puntos ya pasaron.
  final (int actual, int hechos) = switch (s.estado) {
    EstadoSolicitud.borrador => (0, 0),
    EstadoSolicitud.abierta || EstadoSolicitud.conOfertas => (1, 1),
    EstadoSolicitud.adjudicada => (2, 2),
    EstadoSolicitud.enEjecucion => (3, 3),
    EstadoSolicitud.finalizada || EstadoSolicitud.disputada => (4, 4),
    EstadoSolicitud.calificada => (-1, 6),
    EstadoSolicitud.cancelada || EstadoSolicitud.expirada => (
      -1,
      s.historial.any((c) => c.estado == EstadoSolicitud.adjudicada) ? 2 : 1,
    ),
  };
  EstadoHito de(int i) => i == actual
      ? EstadoHito.actual
      : i < hechos
      ? EstadoHito.hecho
      : EstadoHito.pendiente;

  final proveedor = s.nombreProveedor ?? 'El piloto';
  final avance = s.porcentajeAvance?.toStringAsFixed(0) ?? '0';
  return [
    HitoSolicitud(
      clave: 'publicada',
      estado: de(0),
      titulo: 'Solicitud publicada',
      detalle: 'Los pilotos de la zona ven tu precio por hectárea.',
      momento: s.publicadaEn ?? s.momentoDe(EstadoSolicitud.abierta),
    ),
    HitoSolicitud(
      clave: 'ofertas',
      estado: de(1),
      titulo: 'Ofertas de pilotos',
      detalle:
          'Aceptan tu precio o proponen el suyo. Compara y elige a quien '
          'prefieras.',
      momento: s.momentoDe(EstadoSolicitud.conOfertas),
    ),
    HitoSolicitud(
      clave: 'adjudicada',
      estado: de(2),
      titulo: 'Piloto elegido',
      detalle:
          '$proveedor ya tiene tu contacto. Acuerden en persona cómo '
          'trabajar el lote.',
      momento: s.momentoDe(EstadoSolicitud.adjudicada),
    ),
    HitoSolicitud(
      clave: 'ejecucion',
      estado: de(3),
      titulo: 'Fumigación en curso',
      detalle: 'Sigue el avance con las fotos y el chat. Lleva $avance %.',
      momento: s.momentoDe(EstadoSolicitud.enEjecucion),
    ),
    HitoSolicitud(
      clave: 'finalizada',
      estado: de(4),
      titulo: 'Precio final',
      detalle: 'Revisa el resultado y paga al piloto fuera de la app.',
      momento: s.momentoDe(EstadoSolicitud.finalizada),
    ),
    HitoSolicitud(
      clave: 'calificada',
      estado: de(5),
      titulo: 'Calificación',
      detalle: 'Cuenta cómo te fue con el piloto.',
      momento: s.momentoDe(EstadoSolicitud.calificada),
    ),
  ];
}
