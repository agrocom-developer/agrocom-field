import 'package:decimal/decimal.dart';

import 'negociacion.dart';

/// El mapa de solicitudes abiertas. Lectura en línea: el mercado es una
/// competencia entre pilotos y no tiene sentido verlo ni ofertar sin red
/// (ADR 0016).
abstract interface class MercadoRepositorio {
  /// Solicitudes `abierta` y `con_ofertas` que cumplen los filtros. [lat] y
  /// [lon] ordenan por distancia; el servidor no los guarda.
  Future<PaginaSolicitudes> solicitudes(
    FiltrosMapa filtros, {
    String? cursor,
    double? lat,
    double? lon,
  });

  /// Una fila por zona con solicitudes, hectáreas y precio medio.
  Future<List<ResumenZona>> resumenZonas(FiltrosMapa filtros);

  /// El detalle previo a ofertar: lotes, estado del terreno, cultivo y
  /// observaciones.
  Future<SolicitudAbierta> detalle(int solicitudId);

  /// La primera oferta del piloto. Con [TipoOferta.aceptaPropuesta] acepta el
  /// precio del cliente; con [TipoOferta.contraoferta] propone [precioHa].
  /// [uuidCliente] nace en el dispositivo y se conserva entre reintentos: el
  /// servidor devuelve la misma oferta si la respuesta se perdió.
  Future<OfertaNegociada> ofertar({
    required int solicitudId,
    required String uuidCliente,
    required TipoOferta tipo,
    Decimal? precioHa,
    String? nota,
  });
}

/// Las ofertas del propio piloto y su negociación con el cliente.
abstract interface class NegociacionRepositorio {
  /// De la más nueva a la más vieja.
  Future<List<OfertaNegociada>> misOfertas();

  /// Responde a la oferta vigente del cliente con otro precio por hectárea.
  Future<OfertaNegociada> contraofertar(
    int ofertaId, {
    required Decimal precioHa,
    required String uuidCliente,
    String? nota,
  });

  /// Acepta la contraoferta vigente del cliente: adjudica la solicitud.
  Future<OfertaNegociada> aceptar(int ofertaId);

  Future<OfertaNegociada> rechazar(int ofertaId);

  /// Retira la oferta propia mientras sigue vigente.
  Future<OfertaNegociada> retirar(int ofertaId);
}

/// Chat con el cliente, abierto desde la adjudicación. Solo texto: las fotos
/// van como evidencia.
abstract interface class MensajesRepositorio {
  Future<PaginaMensajes> leer(int solicitudId, {int? despues});

  Future<MensajeChat> enviar(
    int solicitudId, {
    required String uuidCliente,
    required String texto,
  });

  Future<void> marcarLeidos(int solicitudId, {required int hasta});
}

/// Preferencias de aviso del piloto (nuevas solicitudes, mensajes...).
abstract interface class AvisosRepositorio {
  Future<PreferenciasAviso> leer();

  Future<PreferenciasAviso> guardar(PreferenciasAviso preferencias);
}
