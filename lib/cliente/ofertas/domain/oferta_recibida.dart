import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/proveedor.dart' show TipoProveedor;

/// Quién escribió una oferta. En cada ronda alterna: el piloto abre y el
/// cliente responde.
enum AutorOferta { proveedor, cliente }

enum EstadoOferta {
  vigente('Vigente'),
  aceptada('Aceptada'),
  reemplazada('Contraofertada'),
  rechazada('Rechazada'),
  retirada('Retirada'),
  vencida('Vencida'),
  cerrada('Cerrada');

  const EstadoOferta(this.etiqueta);
  final String etiqueta;

  static EstadoOferta desdeApi(String? valor) => switch (valor) {
    'aceptada' => aceptada,
    'reemplazada' => reemplazada,
    'rechazada' => rechazada,
    'retirada' => retirada,
    'vencida' => vencida,
    'cerrada' => cerrada,
    _ => vigente,
  };
}

/// Foto aprobada del dron del piloto.
class FotoDron {
  const FotoDron({required this.id, required this.ruta, this.tipo});

  final String id;

  /// Ruta de la API o recurso empaquetado.
  final String ruta;
  final String? tipo;
}

/// Lo que el cliente ve del piloto y su dron en una oferta.
class ProveedorOfertante {
  const ProveedorOfertante({
    required this.id,
    required this.nombre,
    required this.calificacion,
    required this.calificaciones,
    required this.tasaCancelacion,
    this.marcaDron,
    this.modeloDron,
    this.anioDron,
    this.capacidadLitros,
    this.fotosDron = const [],
    this.fotoUrl,
    this.tipo,
  });

  final String id;
  final String nombre;

  /// Promedio de 1 a 5 (no es dinero ni superficie).
  final double calificacion;
  final int calificaciones;

  /// Fracción de 0 a 1 de servicios adjudicados que canceló.
  final double tasaCancelacion;
  final String? marcaDron;
  final String? modeloDron;
  final int? anioDron;
  final Decimal? capacidadLitros;
  final List<FotoDron> fotosDron;

  /// Foto de perfil del piloto: URL firmada de corta vida (15 minutos), que
  /// se pide sin token; `null` si no tiene.
  final String? fotoUrl;

  /// Propio de Agrocom, independiente o dueño de drones; `null` si el
  /// servidor no lo informó.
  final TipoProveedor? tipo;

  String get dron => [?marcaDron, ?modeloDron].join(' ');

  String get iniciales {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }
}

/// Una oferta de la negociación de una solicitud: el precio por hectárea que
/// propone una de las dos partes en esa ronda.
///
/// La app no replica las reglas de la negociación: qué se puede hacer sale de
/// [autor], [estado] y [esDefinitiva] (ADR 0016).
class OfertaRecibida {
  const OfertaRecibida({
    required this.id,
    required this.solicitudId,
    required this.numero,
    required this.autor,
    required this.precioHa,
    required this.montoEstimado,
    required this.estado,
    required this.proveedor,
    this.esDefinitiva = false,
    this.aceptaPropuesta = false,
    this.nota,
    this.justificacionPrecio,
    this.distanciaKm,
    this.venceEn,
    this.creadaEn,
    this.ronda = const [],
  });

  final String id;
  final String solicitudId;

  /// Ronda de la negociación: 1 es la primera oferta del piloto.
  final int numero;
  final AutorOferta autor;

  /// Precio por hectárea.
  final Decimal precioHa;
  final Decimal montoEstimado;
  final EstadoOferta estado;
  final ProveedorOfertante proveedor;

  /// Última ronda: ya no admite contraoferta, solo aceptar o rechazar.
  final bool esDefinitiva;

  /// El piloto acepta exactamente el precio que propuso el cliente.
  final bool aceptaPropuesta;
  final String? nota;

  /// Por qué su autor propone ese precio (hasta 500 caracteres); lo escribe
  /// solo el autor y no se edita.
  final String? justificacionPrecio;
  final Decimal? distanciaKm;
  final DateTime? venceEn;
  final DateTime? creadaEn;

  /// Historial de rondas de esta negociación, de la primera a la última.
  final List<OfertaRecibida> ronda;

  bool vigenteA(DateTime ahora) =>
      estado == EstadoOferta.vigente &&
      (venceEn == null || venceEn!.isAfter(ahora));

  /// La oferta espera la respuesta del cliente: la hizo el piloto y sigue
  /// vigente.
  bool esperaAlCliente(DateTime ahora) =>
      autor == AutorOferta.proveedor && vigenteA(ahora);

  /// El cliente contraofertó y espera al piloto.
  bool esperaAlPiloto(DateTime ahora) =>
      autor == AutorOferta.cliente && vigenteA(ahora);

  /// Cuánto falta para que venza, o `null` si no tiene vencimiento.
  Duration? restante(DateTime ahora) {
    final v = venceEn;
    if (v == null) return null;
    final r = v.difference(ahora);
    return r.isNegative ? Duration.zero : r;
  }
}

/// Resultado de la respuesta del cliente a una oferta.
enum ResultadoRespuesta {
  /// La oferta quedó aceptada y la solicitud, adjudicada.
  adjudicada,

  /// Se envió la contraoferta; ahora responde el piloto.
  contraofertada,

  /// Se rechazó la oferta.
  rechazada,
}

/// El servidor rechazó la respuesta porque la oferta cambió: ya no está
/// vigente, la solicitud se adjudicó a otra o el piloto ya no está
/// disponible. La pantalla lo explica y recarga.
class OfertaCambio implements Exception {
  const OfertaCambio(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'OfertaCambio($mensaje)';
}
