import 'package:decimal/decimal.dart';

import '../../../dominio/dominio.dart';

/// Macrorregiones de Santa Cruz que el mercado distingue para decidir a
/// dónde ir (los valles frente a la Chiquitania).
enum Macrorregion {
  cercado('cercado', 'Cercado'),
  norteIntegrado('norte_integrado', 'Norte integrado'),
  chiquitania('chiquitania', 'Chiquitania'),
  valles('valles', 'Valles'),
  chaco('chaco', 'Chaco');

  const Macrorregion(this.codigo, this.etiqueta);

  /// Valor que viaja en la API.
  final String codigo;
  final String etiqueta;

  /// El orden de los filtros del mapa: primero los valles y la Chiquitania.
  static const ordenDeMapa = [
    valles,
    chiquitania,
    cercado,
    norteIntegrado,
    chaco,
  ];

  static Macrorregion? deCodigo(String? codigo) {
    for (final m in values) {
      if (m.codigo == codigo) return m;
    }
    return null;
  }
}

/// Estado de la negociación del propio proveedor sobre una solicitud
/// (`mi_negociacion` en el mapa).
enum MiNegociacion {
  ninguna('Sin oferta tuya'),
  vigente('Con oferta tuya'),
  cerrada('Negociación cerrada');

  const MiNegociacion(this.etiqueta);
  final String etiqueta;

  static MiNegociacion deCodigo(String? codigo) => switch (codigo) {
    'vigente' => vigente,
    'cerrada' || 'rechazada' || 'aceptada' => cerrada,
    _ => ninguna,
  };
}

/// Una solicitud abierta del mercado, tal como la ve un piloto antes de
/// ofertar: sin nombre, teléfono ni dirección del cliente (esos datos llegan
/// solo tras la adjudicación).
class SolicitudAbierta {
  const SolicitudAbierta({
    required this.id,
    required this.hectareas,
    required this.precioHaPropuesto,
    required this.ofertasVigentes,
    this.centro,
    this.zona,
    this.zonaId,
    this.macrorregion,
    this.cultivo,
    this.tipoAplicacion,
    this.ventanaDesde,
    this.ventanaHasta,
    this.miNegociacion = MiNegociacion.ninguna,
    this.distanciaKm,
    this.venceEn,
    this.productoIndicado,
    this.aportaProducto,
    this.urgente = false,
    this.observaciones,
    this.terreno,
    this.accesoDificil = false,
    this.referenciasAcceso,
    this.colindantesSensibles,
  });

  final int id;
  final GeoPunto? centro;
  final Decimal hectareas;

  /// Lo que propone el cliente por hectárea, en bolivianos.
  final Decimal precioHaPropuesto;
  final String? zona;
  final int? zonaId;
  final Macrorregion? macrorregion;
  final String? cultivo;
  final String? tipoAplicacion;
  final DateTime? ventanaDesde;
  final DateTime? ventanaHasta;

  /// Cuántas ofertas vigentes tiene; no se ven las de otros pilotos.
  final int ofertasVigentes;
  final MiNegociacion miNegociacion;
  final Decimal? distanciaKm;
  final DateTime? venceEn;
  final String? productoIndicado;

  /// `cliente` o `proveedor`: quién pone el producto.
  final String? aportaProducto;
  final bool urgente;
  final String? observaciones;

  /// El terreno con su polígono; solo viene en el detalle.
  final Lote? terreno;
  final bool accesoDificil;
  final String? referenciasAcceso;
  final String? colindantesSensibles;

  /// Monto estimado al precio propuesto: hectáreas por precio.
  Decimal get montoPropuesto => hectareas * precioHaPropuesto;

  /// Punto del mapa: el centro informado o el del polígono del detalle.
  GeoPunto? get ubicacion => centro ?? terreno?.centro;

  bool get puedeOfertar => miNegociacion != MiNegociacion.cerrada;
}

/// Una fila del resumen por zona: cuántas solicitudes, hectáreas y a qué
/// precio medio hay en cada zona.
class ResumenZona {
  const ResumenZona({
    required this.zona,
    required this.solicitudes,
    required this.hectareas,
    required this.precioHaPromedio,
    this.zonaId,
    this.macrorregion,
    this.centro,
  });

  final int? zonaId;
  final String zona;
  final Macrorregion? macrorregion;
  final int solicitudes;
  final Decimal hectareas;
  final Decimal precioHaPromedio;
  final GeoPunto? centro;
}

/// Orden de las solicitudes del mapa.
enum OrdenMapa {
  reciente('reciente', 'Más recientes'),
  distancia('distancia', 'Más cercanas'),
  precioHa('precio_ha', 'Mejor precio'),
  hectareas('hectareas', 'Más hectáreas');

  const OrdenMapa(this.codigo, this.etiqueta);
  final String codigo;
  final String etiqueta;
}

/// Filtros del mapa; todos los decide el usuario (no hay radio fijo).
class FiltrosMapa {
  const FiltrosMapa({
    this.macrorregion,
    this.zonaId,
    this.hectareasMin,
    this.hectareasMax,
    this.precioHaMin,
    this.precioHaMax,
    this.cultivo,
    this.orden = OrdenMapa.reciente,
  });

  final Macrorregion? macrorregion;
  final int? zonaId;
  final Decimal? hectareasMin;
  final Decimal? hectareasMax;
  final Decimal? precioHaMin;
  final Decimal? precioHaMax;
  final String? cultivo;
  final OrdenMapa orden;

  bool get hayFiltros =>
      macrorregion != null ||
      zonaId != null ||
      hectareasMin != null ||
      hectareasMax != null ||
      precioHaMin != null ||
      precioHaMax != null ||
      (cultivo != null && cultivo!.isNotEmpty);

  FiltrosMapa copiarCon({
    Macrorregion? Function()? macrorregion,
    int? Function()? zonaId,
    Decimal? Function()? hectareasMin,
    Decimal? Function()? hectareasMax,
    Decimal? Function()? precioHaMin,
    Decimal? Function()? precioHaMax,
    String? Function()? cultivo,
    OrdenMapa? orden,
  }) => FiltrosMapa(
    macrorregion: macrorregion != null ? macrorregion() : this.macrorregion,
    zonaId: zonaId != null ? zonaId() : this.zonaId,
    hectareasMin: hectareasMin != null ? hectareasMin() : this.hectareasMin,
    hectareasMax: hectareasMax != null ? hectareasMax() : this.hectareasMax,
    precioHaMin: precioHaMin != null ? precioHaMin() : this.precioHaMin,
    precioHaMax: precioHaMax != null ? precioHaMax() : this.precioHaMax,
    cultivo: cultivo != null ? cultivo() : this.cultivo,
    orden: orden ?? this.orden,
  );

  @override
  bool operator ==(Object other) =>
      other is FiltrosMapa &&
      other.macrorregion == macrorregion &&
      other.zonaId == zonaId &&
      other.hectareasMin == hectareasMin &&
      other.hectareasMax == hectareasMax &&
      other.precioHaMin == precioHaMin &&
      other.precioHaMax == precioHaMax &&
      other.cultivo == cultivo &&
      other.orden == orden;

  @override
  int get hashCode => Object.hash(
    macrorregion,
    zonaId,
    hectareasMin,
    hectareasMax,
    precioHaMin,
    precioHaMax,
    cultivo,
    orden,
  );
}

enum TipoOferta { aceptaPropuesta, contraoferta }

enum AutorOferta { proveedor, cliente }

enum EstadoOferta {
  vigente('Vigente', activa: true),
  aceptada('Aceptada', activa: false),
  reemplazada('Respondida', activa: false),
  rechazada('Rechazada', activa: false),
  retirada('Retirada', activa: false),
  vencida('Vencida', activa: false),
  cerrada('Cerrada', activa: false);

  const EstadoOferta(this.etiqueta, {required this.activa});
  final String etiqueta;

  /// Solo una oferta vigente admite responder.
  final bool activa;
}

/// Una oferta o contraoferta de la negociación. La app no replica las reglas
/// (rondas, vigencias, turno): lee `autor`, `estado`, `esDefinitiva` y
/// `venceEn` y habilita lo que el servidor permite.
class OfertaNegociada {
  const OfertaNegociada({
    required this.id,
    required this.uuidCliente,
    required this.solicitudId,
    required this.numero,
    required this.autor,
    required this.tipo,
    required this.precioHa,
    required this.monto,
    required this.estado,
    required this.esDefinitiva,
    required this.venceEn,
    this.nota,
    this.distanciaKm,
    this.creadaEn,
    this.respondidaEn,
    this.zona,
    this.lote,
  });

  final int id;
  final String uuidCliente;
  final int solicitudId;

  /// Ronda de la negociación, desde 1.
  final int numero;
  final AutorOferta autor;
  final TipoOferta tipo;
  final Decimal precioHa;

  /// Monto estimado: hectáreas solicitadas por precio por hectárea.
  final Decimal monto;
  final EstadoOferta estado;
  final bool esDefinitiva;
  final DateTime venceEn;
  final String? nota;
  final Decimal? distanciaKm;
  final DateTime? creadaEn;
  final DateTime? respondidaEn;

  /// Zona de la solicitud, tal como la devuelve el servidor.
  final String? zona;

  /// Nombre del lote del cliente. El servidor solo lo envía cuando la
  /// solicitud quedó adjudicada a este proveedor; antes es nulo.
  final String? lote;

  /// Hectáreas de la solicitud, derivadas del monto estimado del servidor
  /// (hectáreas × precio por hectárea).
  Decimal get hectareas => precioHa == Decimal.zero
      ? Decimal.zero
      : (monto / precioHa).toDecimal(scaleOnInfinitePrecision: 4);

  /// Le toca responder al proveedor: la oferta vigente es del cliente.
  bool get esperaMiRespuesta =>
      estado == EstadoOferta.vigente && autor == AutorOferta.cliente;

  /// Espera al cliente: la oferta vigente es mía.
  bool get esperaAlCliente =>
      estado == EstadoOferta.vigente && autor == AutorOferta.proveedor;

  Duration restante(DateTime ahora) {
    final r = venceEn.difference(ahora);
    return r.isNegative ? Duration.zero : r;
  }
}

/// Resultado de leer el mapa: la página y el cursor de la siguiente.
class PaginaSolicitudes {
  const PaginaSolicitudes({required this.solicitudes, this.siguienteCursor});

  final List<SolicitudAbierta> solicitudes;
  final String? siguienteCursor;
}

/// Mensaje del chat con el cliente (desde la adjudicación).
class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.uuidCliente,
    required this.solicitudId,
    required this.propio,
    required this.texto,
    required this.creadoEn,
    this.leido = false,
  });

  final int id;
  final String uuidCliente;
  final int solicitudId;

  /// Lo escribí yo (el proveedor).
  final bool propio;
  final String texto;
  final DateTime creadoEn;
  final bool leido;
}

class PaginaMensajes {
  const PaginaMensajes({
    required this.mensajes,
    this.cursor,
    this.soloLectura = false,
  });

  final List<MensajeChat> mensajes;
  final int? cursor;

  /// La solicitud ya cerró: se lee pero no se escribe.
  final bool soloLectura;
}

/// Qué avisos recibe el piloto. Las categorías obligatorias (adjudicación,
/// cierre, expiración, cuenta, reclamos, emergencias) no se pueden apagar y
/// por eso no aparecen aquí.
class PreferenciasAviso {
  const PreferenciasAviso({
    this.nuevasSolicitudes = true,
    this.macrorregiones = const [],
    this.hectareasMinimas,
    this.ofertas = true,
    this.mensajes = true,
    this.avance = true,
    this.calificaciones = true,
  });

  final bool nuevasSolicitudes;

  /// Vacío: todas las zonas.
  final List<Macrorregion> macrorregiones;
  final Decimal? hectareasMinimas;
  final bool ofertas;
  final bool mensajes;
  final bool avance;
  final bool calificaciones;

  PreferenciasAviso copiarCon({
    bool? nuevasSolicitudes,
    List<Macrorregion>? macrorregiones,
    Decimal? Function()? hectareasMinimas,
    bool? ofertas,
    bool? mensajes,
    bool? avance,
    bool? calificaciones,
  }) => PreferenciasAviso(
    nuevasSolicitudes: nuevasSolicitudes ?? this.nuevasSolicitudes,
    macrorregiones: macrorregiones ?? this.macrorregiones,
    hectareasMinimas: hectareasMinimas != null
        ? hectareasMinimas()
        : this.hectareasMinimas,
    ofertas: ofertas ?? this.ofertas,
    mensajes: mensajes ?? this.mensajes,
    avance: avance ?? this.avance,
    calificaciones: calificaciones ?? this.calificaciones,
  );

  /// ¿Esta solicitud entra en lo que el piloto pidió que le avisen?
  bool aplicaA(SolicitudAbierta s) {
    if (!nuevasSolicitudes) return false;
    if (macrorregiones.isNotEmpty &&
        (s.macrorregion == null || !macrorregiones.contains(s.macrorregion))) {
      return false;
    }
    final minimo = hectareasMinimas;
    if (minimo != null && s.hectareas < minimo) return false;
    return true;
  }
}
