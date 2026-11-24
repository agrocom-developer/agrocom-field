import '../../../dominio/dominio.dart';

enum CargaOfertas { cargando, lista, error }

/// Por qué una oferta dejó de estar disponible sin que el proveedor la
/// tomara. Ninguno es un error suyo: la pantalla lo cuenta sin alarma.
enum MotivoCierreOferta {
  /// Otro proveedor aceptó antes.
  tomada,

  /// Pasó la ventana de aceptación.
  vencida,
}

/// Oferta que se cerró mientras el proveedor la tenía a la vista.
class OfertaCerrada {
  const OfertaCerrada(this.oferta, this.motivo);

  final Oferta oferta;
  final MotivoCierreOferta motivo;
}

/// Resultado de la última respuesta, para el aviso de la pantalla. [numero]
/// distingue dos avisos iguales seguidos.
class AvisoRespuesta {
  const AvisoRespuesta(this.numero, this.resultado, this.oferta);

  final int numero;
  final ResultadoRespuestaOferta resultado;
  final Oferta oferta;
}

/// Estado de la bandeja de ofertas.
class OfertasEstado {
  const OfertasEstado({
    required this.ahora,
    this.carga = CargaOfertas.cargando,
    this.ofertas = const [],
    this.cerradas = const [],
    this.respondiendo = const {},
    this.enLinea = true,
    this.aviso,
  });

  final CargaOfertas carga;

  /// Ofertas que todavía se pueden responder, de la que vence antes a la que
  /// vence después.
  final List<Oferta> ofertas;

  /// Ofertas que se cerraron (tomadas por otro o vencidas) en esta sesión de
  /// pantalla, hasta que el proveedor las quita.
  final List<OfertaCerrada> cerradas;

  /// Ofertas cuya respuesta está viajando al servidor.
  final Set<String> respondiendo;

  /// Hay red. Sin ella no se puede aceptar ni rechazar.
  final bool enLinea;

  /// Instante con el que se calcula la cuenta regresiva.
  final DateTime ahora;

  final AvisoRespuesta? aviso;

  Oferta? vigente(String id) {
    for (final o in ofertas) {
      if (o.id == id) return o;
    }
    return null;
  }

  OfertaCerrada? cerrada(String id) {
    for (final c in cerradas) {
      if (c.oferta.id == id) return c;
    }
    return null;
  }

  OfertasEstado copiarCon({
    CargaOfertas? carga,
    List<Oferta>? ofertas,
    List<OfertaCerrada>? cerradas,
    Set<String>? respondiendo,
    bool? enLinea,
    DateTime? ahora,
    AvisoRespuesta? aviso,
  }) => OfertasEstado(
    carga: carga ?? this.carga,
    ofertas: ofertas ?? this.ofertas,
    cerradas: cerradas ?? this.cerradas,
    respondiendo: respondiendo ?? this.respondiendo,
    enLinea: enLinea ?? this.enLinea,
    ahora: ahora ?? this.ahora,
    aviso: aviso ?? this.aviso,
  );
}
