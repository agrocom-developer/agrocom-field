import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Foto de avance que el piloto subió, comprimida a menos de 300 KB.
class FotoAvance {
  const FotoAvance({
    required this.id,
    required this.ruta,
    required this.subidaEn,
    this.nota,
  });

  final String id;

  /// Ruta de la API (`/api/evidencias/{id}/archivo`) o recurso empaquetado.
  final String ruta;
  final DateTime subidaEn;
  final String? nota;
}

/// Un registro de avance del piloto: hectáreas acumuladas o porcentaje.
class RegistroAvance {
  const RegistroAvance({
    required this.id,
    required this.tipo,
    required this.momento,
    this.hectareas,
    this.porcentaje,
    this.nota,
  });

  final String id;

  /// `inicio`, `avance` o `cierre`.
  final String tipo;
  final DateTime momento;
  final Decimal? hectareas;
  final Decimal? porcentaje;
  final String? nota;
}

/// Lo que el cliente ve del avance de su servicio: cuánto lleva, qué anotó
/// el piloto y las fotos que subió.
class AvanceServicio {
  const AvanceServicio({
    required this.hectareasSolicitadas,
    this.hectareasEjecutadas,
    this.porcentaje,
    this.precioHaAcordado,
    this.montoFinal,
    this.iniciadaEn,
    this.ultimoAvanceEn,
    this.finalizadaEn,
    this.registros = const [],
    this.fotos = const [],
  });

  final Decimal hectareasSolicitadas;
  final Decimal? hectareasEjecutadas;

  /// De 0 a 100.
  final Decimal? porcentaje;
  final Decimal? precioHaAcordado;
  final Decimal? montoFinal;
  final DateTime? iniciadaEn;
  final DateTime? ultimoAvanceEn;
  final DateTime? finalizadaEn;
  final List<RegistroAvance> registros;
  final List<FotoAvance> fotos;

  /// Avance de 0 a 1, solo para dibujar la barra.
  double get progreso {
    final p = porcentaje;
    if (p == null) return 0;
    return (p.toDouble() / 100).clamp(0.0, 1.0);
  }

  static AvanceServicio vacio(Decimal hectareas) =>
      AvanceServicio(hectareasSolicitadas: hectareas);
}

/// Última posición que la app del piloto reportó. Es un punto, no una ruta:
/// sin recorrido ni tiempo estimado de llegada (ADR 0017).
class UbicacionPiloto {
  const UbicacionPiloto({
    required this.punto,
    required this.capturadaEn,
    required this.vigente,
    this.precisionMetros,
  });

  final GeoPunto punto;
  final DateTime capturadaEn;

  /// Falso si la posición es vieja: la pantalla dice «sin ubicación
  /// reciente» en vez de mostrarla como actual.
  final bool vigente;
  final int? precisionMetros;
}

/// Qué es un mensaje del chat (`tipo` del contrato).
enum TipoMensajeChat { texto, foto, sistema }

/// Un mensaje del chat entre el cliente y el piloto adjudicado. Puede ser de
/// texto, una foto con pie opcional o un evento del sistema (adjudicación,
/// inicio, fin, precio final confirmado).
class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.texto,
    required this.creadoEn,
    required this.propio,
    this.claveCliente,
    this.tipo = TipoMensajeChat.texto,
    this.evento,
    this.ruta,
  });

  final String id;
  final String texto;
  final DateTime creadoEn;

  /// Lo escribió el cliente.
  final bool propio;
  final String? claveCliente;
  final TipoMensajeChat tipo;

  /// Solo en eventos del sistema: `solicitud_adjudicada`,
  /// `servicio_iniciado`, `servicio_finalizado` o `precio_final_confirmado`.
  final String? evento;

  /// Solo en fotos: la ruta de descarga (`/api/mensajes/{id}/archivo`) o un
  /// recurso empaquetado de la demo. En una foto, [texto] es el pie.
  final String? ruta;
}

/// Mensajes con el cursor para pedir los siguientes.
class PaginaMensajes {
  const PaginaMensajes({
    required this.mensajes,
    this.cursor,
    this.soloLectura = false,
  });

  final List<MensajeChat> mensajes;
  final String? cursor;

  /// El plazo del chat cerró: se puede leer, no escribir.
  final bool soloLectura;
}

/// El chat ya no admite mensajes (cerró el plazo o la solicitud).
class ChatCerrado implements Exception {
  const ChatCerrado();
}
