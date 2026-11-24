import 'package:decimal/decimal.dart';

import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

/// Estado en memoria del mercado y la negociación en modo demo (ADR 0010).
/// Datos ficticios de Santa Cruz: valles y Chiquitania.
class AlmacenNegociacionDemo {
  AlmacenNegociacionDemo({
    DateTime Function()? reloj,
    this.latencia = const Duration(milliseconds: 250),
  }) : reloj = reloj ?? DateTime.now {
    final ahora = this.reloj();
    _solicitudes = _sembrar(ahora);
    _ofertas = [
      OfertaNegociada(
        id: 501,
        uuidCliente: 'demo-oferta-501',
        solicitudId: 4,
        numero: 2,
        autor: AutorOferta.cliente,
        tipo: TipoOferta.contraoferta,
        precioHa: Decimal.parse('122'),
        monto: Decimal.parse('12200'),
        estado: EstadoOferta.vigente,
        esDefinitiva: false,
        venceEn: ahora.add(const Duration(hours: 20)),
        nota: 'Tengo otra oferta más baja. ¿Te acercas a este precio?',
        distanciaKm: Decimal.parse('3.3'),
        creadaEn: ahora.subtract(const Duration(hours: 2)),
      ),
      OfertaNegociada(
        id: 502,
        uuidCliente: 'demo-oferta-502',
        solicitudId: 5,
        numero: 1,
        autor: AutorOferta.proveedor,
        tipo: TipoOferta.contraoferta,
        precioHa: Decimal.parse('112'),
        monto: Decimal.parse('28000'),
        estado: EstadoOferta.vigente,
        esDefinitiva: false,
        venceEn: ahora.add(const Duration(hours: 40)),
        distanciaKm: Decimal.parse('96.1'),
        creadaEn: ahora.subtract(const Duration(hours: 5)),
      ),
      OfertaNegociada(
        id: 503,
        uuidCliente: 'demo-oferta-503',
        solicitudId: 2,
        numero: 1,
        autor: AutorOferta.proveedor,
        tipo: TipoOferta.aceptaPropuesta,
        precioHa: Decimal.parse('115'),
        monto: Decimal.parse('10350'),
        estado: EstadoOferta.rechazada,
        esDefinitiva: false,
        venceEn: ahora.subtract(const Duration(days: 1)),
        creadaEn: ahora.subtract(const Duration(days: 2)),
      ),
    ];
    _mensajes = {
      10: [
        MensajeChat(
          id: 1,
          uuidCliente: 'demo-msg-1',
          solicitudId: 10,
          propio: true,
          texto: 'Empezamos. La franja oeste ya está cubierta.',
          creadoEn: ahora.subtract(const Duration(hours: 4)),
        ),
        MensajeChat(
          id: 2,
          uuidCliente: 'demo-msg-2',
          solicitudId: 10,
          propio: false,
          texto: 'Gracias por avisar. Mañana paso por el lote.',
          creadoEn: ahora.subtract(const Duration(hours: 3)),
        ),
      ],
    };
  }

  final DateTime Function() reloj;

  /// Espera simulada de la red; las pruebas la dejan en cero.
  final Duration latencia;
  late List<SolicitudAbierta> _solicitudes;
  late List<OfertaNegociada> _ofertas;
  late Map<int, List<MensajeChat>> _mensajes;
  PreferenciasAviso preferencias = const PreferenciasAviso();
  bool enLinea = true;
  int _siguienteId = 900;

  List<SolicitudAbierta> get solicitudes => List.unmodifiable(_solicitudes);
  List<OfertaNegociada> get ofertas => List.unmodifiable(_ofertas);

  int nuevoId() => _siguienteId++;

  void reemplazarOferta(OfertaNegociada nueva) {
    _ofertas = [
      nueva,
      for (final o in _ofertas)
        if (o.id != nueva.id) o,
    ];
  }

  void agregarOferta(OfertaNegociada nueva) => _ofertas = [nueva, ..._ofertas];

  List<MensajeChat> mensajesDe(int solicitudId) =>
      List.unmodifiable(_mensajes[solicitudId] ?? const []);

  void agregarMensaje(MensajeChat m) =>
      _mensajes[m.solicitudId] = [...?_mensajes[m.solicitudId], m];

  static Lote _lote(
    int id,
    String zona,
    String cultivo,
    String ha,
    GeoPunto c,
  ) {
    const d = 0.006;
    return Lote(
      id: 'demo-terreno-$id',
      nombre: 'Lote ${String.fromCharCode(64 + id)}',
      zona: zona,
      cultivo: cultivo,
      hectareas: Decimal.parse(ha),
      poligono: [
        GeoPunto(c.latitud - d, c.longitud - d),
        GeoPunto(c.latitud - d, c.longitud + d),
        GeoPunto(c.latitud + d, c.longitud + d),
        GeoPunto(c.latitud + d, c.longitud - d),
      ],
    );
  }

  static SolicitudAbierta _solicitud(
    int id, {
    required String zona,
    required int zonaId,
    required Macrorregion macro,
    required String cultivo,
    required String ha,
    required String precio,
    required GeoPunto centro,
    required DateTime ahora,
    int ofertas = 0,
    MiNegociacion mia = MiNegociacion.ninguna,
    String? observaciones,
    bool accesoDificil = false,
  }) => SolicitudAbierta(
    id: id,
    centro: centro,
    hectareas: Decimal.parse(ha),
    precioHaPropuesto: Decimal.parse(precio),
    ofertasVigentes: ofertas,
    zona: zona,
    zonaId: zonaId,
    macrorregion: macro,
    cultivo: cultivo,
    tipoAplicacion: 'herbicida',
    ventanaDesde: ahora.add(const Duration(days: 2)),
    ventanaHasta: ahora.add(const Duration(days: 8)),
    miNegociacion: mia,
    venceEn: ahora.add(const Duration(days: 6)),
    productoIndicado: 'Glifosato 480 SL, 2 L/ha',
    aportaProducto: 'cliente',
    observaciones: observaciones,
    terreno: _lote(id, zona, cultivo, ha, centro),
    accesoDificil: accesoDificil,
    referenciasAcceso: 'Camino vecinal a 3 km de la ruta principal.',
  );

  static List<SolicitudAbierta> _sembrar(DateTime ahora) => [
    _solicitud(
      1,
      zona: 'Warnes',
      zonaId: 2,
      macro: Macrorregion.norteIntegrado,
      cultivo: 'Soya',
      ha: '40',
      precio: '121',
      centro: const GeoPunto(-17.5351, -63.1978),
      ahora: ahora,
      observaciones: 'Hay una línea de alta tensión en el borde sur.',
    ),
    _solicitud(
      2,
      zona: 'Montero',
      zonaId: 3,
      macro: Macrorregion.norteIntegrado,
      cultivo: 'Maíz',
      ha: '90',
      precio: '115',
      centro: const GeoPunto(-17.3205, -63.2838),
      ahora: ahora,
      ofertas: 1,
      mia: MiNegociacion.cerrada,
    ),
    _solicitud(
      3,
      zona: 'Vallegrande',
      zonaId: 11,
      macro: Macrorregion.valles,
      cultivo: 'Maní',
      ha: '60',
      precio: '130',
      centro: const GeoPunto(-18.49, -64.08),
      ahora: ahora,
      accesoDificil: true,
      observaciones: 'Terreno con pendiente. Acceso por camino de ripio.',
    ),
    _solicitud(
      4,
      zona: 'Santa Cruz de la Sierra',
      zonaId: 1,
      macro: Macrorregion.cercado,
      cultivo: 'Soya',
      ha: '100',
      precio: '125',
      centro: const GeoPunto(-17.7843, -63.2131),
      ahora: ahora,
      ofertas: 2,
      mia: MiNegociacion.vigente,
    ),
    _solicitud(
      5,
      zona: 'San Ignacio de Velasco',
      zonaId: 10,
      macro: Macrorregion.chiquitania,
      cultivo: 'Soya',
      ha: '250',
      precio: '105',
      centro: const GeoPunto(-16.3543, -60.9343),
      ahora: ahora,
      ofertas: 1,
      mia: MiNegociacion.vigente,
    ),
    _solicitud(
      6,
      zona: 'San José de Chiquitos',
      zonaId: 9,
      macro: Macrorregion.chiquitania,
      cultivo: 'Sorgo',
      ha: '180',
      precio: '118',
      centro: const GeoPunto(-17.846, -60.74),
      ahora: ahora,
    ),
  ];
}

bool _coincide(SolicitudAbierta s, FiltrosMapa f) {
  if (f.macrorregion != null && s.macrorregion != f.macrorregion) return false;
  if (f.zonaId != null && s.zonaId != f.zonaId) return false;
  if (f.hectareasMin != null && s.hectareas < f.hectareasMin!) return false;
  if (f.hectareasMax != null && s.hectareas > f.hectareasMax!) return false;
  if (f.precioHaMin != null && s.precioHaPropuesto < f.precioHaMin!) {
    return false;
  }
  if (f.precioHaMax != null && s.precioHaPropuesto > f.precioHaMax!) {
    return false;
  }
  final cultivo = f.cultivo?.trim().toLowerCase();
  if (cultivo != null &&
      cultivo.isNotEmpty &&
      !(s.cultivo ?? '').toLowerCase().contains(cultivo)) {
    return false;
  }
  return true;
}

Future<T> _conRed<T>(AlmacenNegociacionDemo a, Future<T> Function() f) async {
  await Future<void>.delayed(a.latencia);
  if (!a.enLinea) throw const SinConexion();
  return f();
}

class MercadoDemo implements MercadoRepositorio {
  MercadoDemo(this._a);

  final AlmacenNegociacionDemo _a;

  @override
  Future<PaginaSolicitudes> solicitudes(
    FiltrosMapa filtros, {
    String? cursor,
    double? lat,
    double? lon,
  }) => _conRed(_a, () async {
    final lista = [
      for (final s in _a.solicitudes)
        if (_coincide(s, filtros)) s,
    ];
    switch (filtros.orden) {
      case OrdenMapa.precioHa:
        lista.sort(
          (x, y) => y.precioHaPropuesto.compareTo(x.precioHaPropuesto),
        );
      case OrdenMapa.hectareas:
        lista.sort((x, y) => y.hectareas.compareTo(x.hectareas));
      case OrdenMapa.reciente || OrdenMapa.distancia:
        break;
    }
    return PaginaSolicitudes(solicitudes: lista);
  });

  @override
  Future<List<ResumenZona>> resumenZonas(FiltrosMapa filtros) => _conRed(
    _a,
    () async {
      final porZona = <int, List<SolicitudAbierta>>{};
      for (final s in _a.solicitudes) {
        if (_coincide(s, filtros) && s.zonaId != null) {
          porZona.putIfAbsent(s.zonaId!, () => []).add(s);
        }
      }
      return [
        for (final e in porZona.entries)
          ResumenZona(
            zonaId: e.key,
            zona: e.value.first.zona ?? 'Sin zona',
            macrorregion: e.value.first.macrorregion,
            solicitudes: e.value.length,
            hectareas: e.value.fold(Decimal.zero, (a, s) => a + s.hectareas),
            precioHaPromedio:
                (e.value.fold(Decimal.zero, (a, s) => a + s.precioHaPropuesto) /
                        Decimal.fromInt(e.value.length))
                    .toDecimal(scaleOnInfinitePrecision: 2),
            centro: e.value.first.centro,
          ),
      ];
    },
  );

  @override
  Future<SolicitudAbierta> detalle(int solicitudId) => _conRed(_a, () async {
    for (final s in _a.solicitudes) {
      if (s.id == solicitudId) return s;
    }
    throw const OperacionRechazada('Esta solicitud ya no está abierta.');
  });

  @override
  Future<OfertaNegociada> ofertar({
    required int solicitudId,
    required String uuidCliente,
    required TipoOferta tipo,
    Decimal? precioHa,
    String? nota,
  }) => _conRed(_a, () async {
    for (final o in _a.ofertas) {
      if (o.uuidCliente == uuidCliente) return o;
    }
    final s = _a.solicitudes.firstWhere((s) => s.id == solicitudId);
    final precio = tipo == TipoOferta.aceptaPropuesta
        ? s.precioHaPropuesto
        : precioHa!;
    final oferta = OfertaNegociada(
      id: _a.nuevoId(),
      uuidCliente: uuidCliente,
      solicitudId: solicitudId,
      numero: 1,
      autor: AutorOferta.proveedor,
      tipo: tipo,
      precioHa: precio,
      monto: s.hectareas * precio,
      estado: EstadoOferta.vigente,
      esDefinitiva: false,
      venceEn: _a.reloj().add(const Duration(hours: 48)),
      nota: nota,
      creadaEn: _a.reloj(),
    );
    _a.agregarOferta(oferta);
    return oferta;
  });
}

class NegociacionDemo implements NegociacionRepositorio {
  NegociacionDemo(this._a);

  final AlmacenNegociacionDemo _a;

  OfertaNegociada _buscar(int id) => _a.ofertas.firstWhere((o) => o.id == id);

  OfertaNegociada _con(OfertaNegociada o, EstadoOferta estado) {
    final nueva = OfertaNegociada(
      id: o.id,
      uuidCliente: o.uuidCliente,
      solicitudId: o.solicitudId,
      numero: o.numero,
      autor: o.autor,
      tipo: o.tipo,
      precioHa: o.precioHa,
      monto: o.monto,
      estado: estado,
      esDefinitiva: o.esDefinitiva,
      venceEn: o.venceEn,
      nota: o.nota,
      distanciaKm: o.distanciaKm,
      creadaEn: o.creadaEn,
      respondidaEn: _a.reloj(),
    );
    _a.reemplazarOferta(nueva);
    return nueva;
  }

  @override
  Future<List<OfertaNegociada>> misOfertas() =>
      _conRed(_a, () async => _a.ofertas);

  @override
  Future<OfertaNegociada> contraofertar(
    int ofertaId, {
    required Decimal precioHa,
    required String uuidCliente,
    String? nota,
  }) => _conRed(_a, () async {
    final anterior = _buscar(ofertaId);
    _con(anterior, EstadoOferta.reemplazada);
    final s = _a.solicitudes.firstWhere((s) => s.id == anterior.solicitudId);
    final nueva = OfertaNegociada(
      id: _a.nuevoId(),
      uuidCliente: uuidCliente,
      solicitudId: anterior.solicitudId,
      numero: anterior.numero + 1,
      autor: AutorOferta.proveedor,
      tipo: TipoOferta.contraoferta,
      precioHa: precioHa,
      monto: s.hectareas * precioHa,
      estado: EstadoOferta.vigente,
      esDefinitiva: false,
      venceEn: _a.reloj().add(const Duration(hours: 48)),
      nota: nota,
      creadaEn: _a.reloj(),
    );
    _a.agregarOferta(nueva);
    return nueva;
  });

  @override
  Future<OfertaNegociada> aceptar(int ofertaId) =>
      _conRed(_a, () async => _con(_buscar(ofertaId), EstadoOferta.aceptada));

  @override
  Future<OfertaNegociada> rechazar(int ofertaId) =>
      _conRed(_a, () async => _con(_buscar(ofertaId), EstadoOferta.rechazada));

  @override
  Future<OfertaNegociada> retirar(int ofertaId) =>
      _conRed(_a, () async => _con(_buscar(ofertaId), EstadoOferta.retirada));
}

class MensajesDemo implements MensajesRepositorio {
  MensajesDemo(this._a);

  final AlmacenNegociacionDemo _a;

  @override
  Future<PaginaMensajes> leer(int solicitudId, {int? despues}) =>
      _conRed(_a, () async {
        final todos = _a.mensajesDe(solicitudId);
        return PaginaMensajes(
          mensajes: [
            for (final m in todos)
              if (despues == null || m.id > despues) m,
          ],
          cursor: todos.isEmpty ? null : todos.last.id,
        );
      });

  @override
  Future<MensajeChat> enviar(
    int solicitudId, {
    required String uuidCliente,
    required String texto,
  }) => _conRed(_a, () async {
    for (final m in _a.mensajesDe(solicitudId)) {
      if (m.uuidCliente == uuidCliente) return m;
    }
    final m = MensajeChat(
      id: _a.nuevoId(),
      uuidCliente: uuidCliente,
      solicitudId: solicitudId,
      propio: true,
      texto: texto.trim(),
      creadoEn: _a.reloj(),
    );
    _a.agregarMensaje(m);
    return m;
  });

  @override
  Future<void> marcarLeidos(int solicitudId, {required int hasta}) async {}
}

class AvisosDemo implements AvisosRepositorio {
  AvisosDemo(this._a);

  final AlmacenNegociacionDemo _a;

  @override
  Future<PreferenciasAviso> leer() => _conRed(_a, () async => _a.preferencias);

  @override
  Future<PreferenciasAviso> guardar(PreferenciasAviso preferencias) =>
      _conRed(_a, () async => _a.preferencias = preferencias);
}
