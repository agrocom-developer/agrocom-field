import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../nucleo/marketplace/demo/datos_demo.dart';
import '../../nucleo/marketplace/dominio/dominio.dart';
import '../acceso/domain/acceso_repositorio.dart';
import '../ofertas/domain/oferta_recibida.dart';
import '../seguimiento/domain/seguimiento.dart';
import '../solicitudes/domain/solicitud.dart';

Decimal _d(String v) => Decimal.parse(v);

/// Estado en memoria del flavor cliente en modo demo: los repositorios fake
/// de cada feature lo comparten para que una solicitud nueva aparezca en la
/// lista, una oferta aceptada adjudique y una calificación quede guardada. Se
/// pierde al cerrar la app.
///
/// Con [respuestasAutomaticas] la demo simula a los pilotos: ofertan unos
/// segundos después de publicar, responden las contraofertas y contestan el
/// chat. Las pruebas lo apagan para controlar el tiempo.
class AlmacenDemoCliente {
  AlmacenDemoCliente({
    DatosDemo? datos,
    this.respuestasAutomaticas = false,
    this.espera = const Duration(seconds: 3),
  }) : datos = datos ?? DatosDemo() {
    _sembrar();
  }

  final DatosDemo datos;
  final bool respuestasAutomaticas;

  /// Cuánto tarda un piloto simulado en responder.
  final Duration espera;

  final _solicitudes = <Solicitud>[];
  final _ofertas = <String, List<OfertaRecibida>>{};
  final _avances = <String, AvanceServicio>{};
  final _ubicaciones = <String, GeoPunto>{};
  final _mensajes = <String, List<MensajeChat>>{};
  final _cambios = StreamController<List<Solicitud>>.broadcast();
  final _porClave = <String, Solicitud>{};
  final _temporizadores = <Timer>[];
  var _siguiente = 5000;

  /// Sesión del cliente en la demo; `null` mientras nadie haya entrado.
  SesionCliente? sesion;

  /// Calificaciones que el cliente emitió en esta sesión, por solicitud.
  final calificaciones = <String, CalificacionEmitida>{};

  /// Problemas reportados en esta sesión, por solicitud (uno por solicitud).
  final problemas = <String, ProblemaReportado>{};

  /// Simula la falta de red: con `true`, los repositorios demo lanzan
  /// [SinConexion]. Sirve para ver y probar los estados sin conexión.
  bool sinRed = false;

  /// Lanza [SinConexion] si la demo está simulando la falta de red.
  void exigirRed() {
    if (sinRed) throw const SinConexion();
  }

  DateTime get ahora => datos.ahora;

  // ── Solicitudes ───────────────────────────────────────────────────────

  List<Solicitud> get solicitudes => List.unmodifiable(_solicitudes);

  Stream<List<Solicitud>> observar() async* {
    yield solicitudes;
    yield* _cambios.stream;
  }

  Solicitud? porId(String id) {
    for (final s in _solicitudes) {
      if (s.id == id) return s;
    }
    return null;
  }

  void reemplazar(Solicitud actualizada) {
    final i = _solicitudes.indexWhere((s) => s.id == actualizada.id);
    if (i < 0) return;
    _solicitudes[i] = actualizada;
    _avisar();
  }

  /// Avisa a quienes observan sin cambiar nada (equivale a refrescar).
  void reemplazarTodas() => _avisar();

  void _avisar() {
    // Con las ofertas al día, cada solicitud sabe cuántas vigentes tiene.
    for (var i = 0; i < _solicitudes.length; i++) {
      final s = _solicitudes[i];
      _solicitudes[i] = s.copiarCon(ofertasVigentes: _vigentes(s.id));
    }
    if (!_cambios.isClosed) _cambios.add(solicitudes);
  }

  int _vigentes(String id) => (_ofertas[id] ?? const [])
      .where((o) => o.estado == EstadoOferta.vigente)
      .length;

  /// Agrega la solicitud de un formulario; la misma clave devuelve la misma
  /// solicitud (idempotencia).
  Solicitud agregarSolicitud(String clave, Solicitud nueva) {
    final previa = _porClave[clave];
    if (previa != null) return previa;
    _porClave[clave] = nueva;
    _solicitudes.insert(0, nueva);
    _ofertas[nueva.id] = [];
    _avisar();
    if (respuestasAutomaticas) _simularOfertas(nueva);
    return nueva;
  }

  String nuevoId() => '${_siguiente++}';

  // ── Ofertas ───────────────────────────────────────────────────────────

  List<OfertaRecibida> ofertasDe(String solicitudId) =>
      List.unmodifiable(_ofertas[solicitudId] ?? const []);

  void agregarOferta(OfertaRecibida oferta) {
    final lista = _ofertas.putIfAbsent(oferta.solicitudId, () => []);
    lista.add(oferta);
    final s = porId(oferta.solicitudId);
    if (s != null &&
        (s.estado == EstadoSolicitud.abierta ||
            s.estado == EstadoSolicitud.conOfertas)) {
      reemplazar(s.copiarCon(estado: EstadoSolicitud.conOfertas));
    } else {
      _avisar();
    }
  }

  void _cambiarOferta(String id, OfertaRecibida Function(OfertaRecibida) f) {
    for (final lista in _ofertas.values) {
      final i = lista.indexWhere((o) => o.id == id);
      if (i >= 0) {
        lista[i] = f(lista[i]);
        return;
      }
    }
  }

  OfertaRecibida? ofertaPorId(String id) {
    for (final lista in _ofertas.values) {
      for (final o in lista) {
        if (o.id == id) return o;
      }
    }
    return null;
  }

  OfertaRecibida _copiar(OfertaRecibida o, EstadoOferta estado) =>
      OfertaRecibida(
        id: o.id,
        solicitudId: o.solicitudId,
        numero: o.numero,
        autor: o.autor,
        precioHa: o.precioHa,
        montoEstimado: o.montoEstimado,
        estado: estado,
        proveedor: o.proveedor,
        esDefinitiva: o.esDefinitiva,
        aceptaPropuesta: o.aceptaPropuesta,
        nota: o.nota,
        distanciaKm: o.distanciaKm,
        venceEn: o.venceEn,
        creadaEn: o.creadaEn,
        ronda: o.ronda,
      );

  /// Adjudica la solicitud a [oferta]: las demás ofertas vigentes se cierran
  /// y se abre el chat con el piloto.
  void adjudicar(OfertaRecibida oferta) {
    final s = porId(oferta.solicitudId);
    if (s == null) return;
    for (final o in List.of(_ofertas[s.id] ?? const <OfertaRecibida>[])) {
      if (o.id == oferta.id) {
        _cambiarOferta(o.id, (x) => _copiar(x, EstadoOferta.aceptada));
      } else if (o.estado == EstadoOferta.vigente) {
        _cambiarOferta(o.id, (x) => _copiar(x, EstadoOferta.cerrada));
      }
    }
    reemplazar(
      Solicitud(
        id: s.id,
        lote: s.lote,
        hectareas: s.hectareas,
        cultivo: s.cultivo,
        producto: s.producto,
        tipoAplicacion: s.tipoAplicacion,
        ventanaDesde: s.ventanaDesde,
        ventanaHasta: s.ventanaHasta,
        observaciones: s.observaciones,
        accesos: s.accesos,
        precioHaPropuesto: s.precioHaPropuesto,
        precioHaAcordado: oferta.precioHa,
        montoEstimado: s.hectareas * oferta.precioHa,
        estado: EstadoSolicitud.adjudicada,
        proveedorId: oferta.proveedor.id,
        ofertaAdjudicadaId: oferta.id,
        venceEn: s.venceEn,
        publicadaEn: s.publicadaEn,
        historial: [
          ...s.historial,
          CambioEstado(estado: EstadoSolicitud.adjudicada, momento: ahora),
        ],
        nombreProveedor: oferta.proveedor.nombre,
      ),
    );
    _avances[s.id] = AvanceServicio.vacio(s.hectareas);
    // Al adjudicar, el sistema abre el chat con su evento, como el servidor.
    _mensajes[s.id] = [
      MensajeChat(
        id: 'm-${_siguiente++}',
        texto: 'La solicitud quedó adjudicada. Ya pueden coordinar por aquí.',
        creadoEn: ahora,
        propio: false,
        tipo: TipoMensajeChat.sistema,
        evento: 'solicitud_adjudicada',
      ),
    ];
    if (respuestasAutomaticas) {
      _tras(
        () => agregarMensaje(
          s.id,
          MensajeChat(
            id: 'm-${_siguiente++}',
            texto:
                'Hola, soy ${oferta.proveedor.nombre.split(' ').first}. '
                'Quedamos en el precio; ¿coordinamos el día de la visita?',
            creadoEn: ahora,
            propio: false,
          ),
        ),
      );
    }
  }

  /// Reemplaza la oferta vigente por la siguiente ronda de la contraparte.
  OfertaRecibida contraofertar(
    OfertaRecibida anterior,
    AutorOferta autor,
    Decimal precioHa, {
    String? nota,
  }) {
    _cambiarOferta(anterior.id, (x) => _copiar(x, EstadoOferta.reemplazada));
    final numero = anterior.numero + 1;
    final s = porId(anterior.solicitudId);
    final nueva = OfertaRecibida(
      id: 'of-${_siguiente++}',
      solicitudId: anterior.solicitudId,
      numero: numero,
      autor: autor,
      precioHa: precioHa,
      montoEstimado: (s?.hectareas ?? Decimal.zero) * precioHa,
      estado: EstadoOferta.vigente,
      proveedor: anterior.proveedor,
      esDefinitiva: numero >= 5,
      nota: nota,
      distanciaKm: anterior.distanciaKm,
      venceEn: ahora.add(const Duration(hours: 24)),
      creadaEn: ahora,
      ronda: [...anterior.ronda, anterior],
    );
    _ofertas[anterior.solicitudId]!.add(nueva);
    _avisar();
    return nueva;
  }

  void rechazarOferta(OfertaRecibida oferta) {
    _cambiarOferta(oferta.id, (x) => _copiar(x, EstadoOferta.rechazada));
    final s = porId(oferta.solicitudId);
    if (s != null && _vigentes(s.id) == 0 && s.estado.negociando) {
      reemplazar(s.copiarCon(estado: EstadoSolicitud.abierta));
    } else {
      _avisar();
    }
  }

  // ── Seguimiento ───────────────────────────────────────────────────────

  AvanceServicio avanceDe(String id) =>
      _avances[id] ??
      AvanceServicio.vacio(porId(id)?.hectareas ?? Decimal.zero);

  GeoPunto? ubicacionDe(String id) => _ubicaciones[id];

  List<MensajeChat> mensajesDe(String id) =>
      List.unmodifiable(_mensajes[id] ?? const []);

  void agregarMensaje(String id, MensajeChat mensaje) {
    (_mensajes[id] ??= []).add(mensaje);
    if (!_cambios.isClosed) _cambios.add(solicitudes);
  }

  // ── Pilotos simulados ─────────────────────────────────────────────────

  void _tras(void Function() accion, [Duration? tras]) {
    if (_cambios.isClosed) return;
    _temporizadores.add(
      Timer(tras ?? espera, () {
        if (!_cambios.isClosed) accion();
      }),
    );
  }

  ProveedorOfertante ofertante(String idProveedor, Dron dron) {
    final p = datos.proveedorPorId(idProveedor);
    return ProveedorOfertante(
      id: p.id,
      nombre: p.nombre,
      calificacion: p.calificacion,
      calificaciones: p.serviciosCompletados,
      tasaCancelacion: 0.02,
      marcaDron: 'DJI',
      modeloDron: dron.modelo.replaceFirst('DJI ', ''),
      anioDron: 2024,
      capacidadLitros: dron.capacidadLitros,
    );
  }

  /// Dos pilotos simulados ofertan sobre una solicitud nueva: uno acepta el
  /// precio y otro contraoferta.
  void _simularOfertas(Solicitud s) {
    final drones = datos.drones;
    _tras(() {
      agregarOferta(
        OfertaRecibida(
          id: 'of-${_siguiente++}',
          solicitudId: s.id,
          numero: 1,
          autor: AutorOferta.proveedor,
          precioHa: s.precioHaPropuesto,
          montoEstimado: s.hectareas * s.precioHaPropuesto,
          estado: EstadoOferta.vigente,
          aceptaPropuesta: true,
          proveedor: ofertante('prov-rodrigo', drones.first),
          distanciaKm: _d('18.4'),
          venceEn: ahora.add(const Duration(hours: 24)),
          creadaEn: ahora,
        ),
      );
    });
    _tras(() {
      final mas = s.precioHaPropuesto * _d('1.12');
      agregarOferta(
        OfertaRecibida(
          id: 'of-${_siguiente++}',
          solicitudId: s.id,
          numero: 1,
          autor: AutorOferta.proveedor,
          precioHa: mas.round(scale: 0),
          montoEstimado: s.hectareas * mas.round(scale: 0),
          estado: EstadoOferta.vigente,
          nota: 'Tengo el dron libre esa semana.',
          proveedor: ofertante('prov-daniela', drones[1 % drones.length]),
          distanciaKm: _d('41.0'),
          venceEn: ahora.add(const Duration(hours: 24)),
          creadaEn: ahora,
        ),
      );
    }, espera * 2);
  }

  /// Un piloto simulado responde a la contraoferta del cliente con el punto
  /// medio, hasta que la ronda es definitiva.
  void responderContraoferta(OfertaRecibida cliente, Decimal precioPrevio) {
    if (!respuestasAutomaticas) return;
    _tras(() {
      final vigente = ofertaPorId(cliente.id);
      if (vigente == null || vigente.estado != EstadoOferta.vigente) return;
      final medio = ((cliente.precioHa + precioPrevio) / _d('2'))
          .toDecimal(scaleOnInfinitePrecision: 2)
          .round(scale: 0);
      contraofertar(vigente, AutorOferta.proveedor, medio);
    });
  }

  void responderMensaje(String solicitudId) {
    if (!respuestasAutomaticas) return;
    _tras(
      () => agregarMensaje(
        solicitudId,
        MensajeChat(
          id: 'm-${_siguiente++}',
          texto: 'Perfecto, quedamos así. Te aviso cuando salga hacia el lote.',
          creadoEn: ahora,
          propio: false,
        ),
      ),
      espera ~/ 2,
    );
  }

  void cerrar() {
    for (final t in _temporizadores) {
      t.cancel();
    }
    _cambios.close();
  }

  // ── Datos de arranque ─────────────────────────────────────────────────

  void _sembrar() {
    final ahora = datos.ahora;
    DateTime hace(Duration d) => ahora.subtract(d);
    final lotes = datos.lotes;
    final drones = datos.drones;

    Solicitud base(
      String id,
      Lote lote,
      Decimal ha,
      String producto,
      Decimal propuesto,
      EstadoSolicitud estado, {
      DateTime? desde,
      Decimal? acordado,
      Decimal? ejecutadas,
      Decimal? porcentaje,
      Decimal? montoFinal,
      String? proveedorId,
      String? nombreProveedor,
      int? puntaje,
      String? motivo,
      required List<CambioEstado> historial,
    }) => Solicitud(
      id: id,
      lote: lote,
      hectareas: ha,
      cultivo: lote.cultivo,
      producto: producto,
      ventanaDesde: desde ?? ahora.add(const Duration(days: 3)),
      ventanaHasta: (desde ?? ahora.add(const Duration(days: 3))).add(
        const Duration(days: 3),
      ),
      accesos: 'Camino vecinal a 3 km de la ruta; portón azul.',
      precioHaPropuesto: propuesto,
      precioHaAcordado: acordado,
      montoEstimado: ha * (acordado ?? propuesto),
      hectareasEjecutadas: ejecutadas,
      porcentajeAvance: porcentaje,
      montoFinal: montoFinal,
      estado: estado,
      proveedorId: proveedorId,
      ofertaAdjudicadaId: acordado == null ? null : 'of-$id',
      publicadaEn: historial.isEmpty ? null : historial.first.momento,
      venceEn: ahora.add(const Duration(days: 5)),
      historial: historial,
      nombreProveedor: nombreProveedor,
      puntajeDelCliente: puntaje,
      motivoCancelacion: motivo,
    );

    // 1. Abierta con tres ofertas para comparar.
    final abierta = base(
      '4101',
      lotes[0],
      lotes[0].hectareas,
      'Glifosato 480 SL, 2 L/ha',
      _d('110'),
      EstadoSolicitud.conOfertas,
      historial: [
        CambioEstado(
          estado: EstadoSolicitud.abierta,
          momento: hace(const Duration(hours: 20)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.conOfertas,
          momento: hace(const Duration(hours: 18)),
        ),
      ],
    );
    _solicitudes.add(abierta);
    OfertaRecibida oferta(
      String n,
      String proveedor,
      Dron dron,
      String precio,
      String km, {
      AutorOferta autor = AutorOferta.proveedor,
      bool acepta = false,
      int numero = 1,
      String? nota,
    }) => OfertaRecibida(
      id: 'of-$n',
      solicitudId: abierta.id,
      numero: numero,
      autor: autor,
      precioHa: _d(precio),
      montoEstimado: abierta.hectareas * _d(precio),
      estado: EstadoOferta.vigente,
      aceptaPropuesta: acepta,
      nota: nota,
      proveedor: ofertante(proveedor, dron),
      distanciaKm: _d(km),
      venceEn: ahora.add(const Duration(hours: 22)),
      creadaEn: hace(const Duration(hours: 17)),
    );
    _ofertas[abierta.id] = [
      oferta('4101-a', 'prov-rodrigo', drones[0], '110', '18.4', acepta: true),
      oferta(
        '4101-b',
        'prov-marcelo',
        drones[1 % drones.length],
        '104',
        '32.7',
        nota: 'Puedo ir el jueves en la mañana.',
      ),
      oferta('4101-c', 'prov-daniela', drones[2 % drones.length], '121', '9.8'),
    ];

    // 2. En ejecución, con avance, fotos, chat y ubicación del piloto.
    final lote2 = lotes[1];
    final marcelo = datos.proveedorPorId('prov-marcelo');
    final ejecucion = base(
      '4102',
      lote2,
      lote2.hectareas,
      'Insecticida piretroide',
      _d('115'),
      EstadoSolicitud.enEjecucion,
      desde: ahora,
      acordado: _d('118'),
      ejecutadas: _d('52.0'),
      porcentaje: _d('60.82'),
      proveedorId: marcelo.id,
      nombreProveedor: marcelo.nombre,
      historial: [
        CambioEstado(
          estado: EstadoSolicitud.abierta,
          momento: hace(const Duration(days: 3)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.adjudicada,
          momento: hace(const Duration(days: 2)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.enEjecucion,
          momento: hace(const Duration(hours: 5)),
        ),
      ],
    );
    _solicitudes.add(ejecucion);
    _avances[ejecucion.id] = AvanceServicio(
      hectareasSolicitadas: ejecucion.hectareas,
      hectareasEjecutadas: _d('52.0'),
      porcentaje: _d('60.82'),
      precioHaAcordado: _d('118'),
      iniciadaEn: hace(const Duration(hours: 5)),
      ultimoAvanceEn: hace(const Duration(minutes: 40)),
      registros: [
        RegistroAvance(
          id: 'r1',
          tipo: 'avance',
          momento: hace(const Duration(hours: 3)),
          hectareas: _d('26.0'),
          porcentaje: _d('30.41'),
          nota: 'Primera franja, lado oeste.',
        ),
        RegistroAvance(
          id: 'r2',
          tipo: 'avance',
          momento: hace(const Duration(minutes: 40)),
          hectareas: _d('52.0'),
          porcentaje: _d('60.82'),
          nota: 'Sector central terminado.',
        ),
      ],
      fotos: [
        FotoAvance(
          id: 'f1',
          ruta: 'assets/imagenes/fondo_dron_pulverizando.jpg',
          subidaEn: hace(const Duration(hours: 3)),
          nota: 'Primera franja, lado oeste.',
        ),
        FotoAvance(
          id: 'f2',
          ruta: 'assets/imagenes/fondo_dron_sobre_agua.jpg',
          subidaEn: hace(const Duration(minutes: 40)),
          nota: 'Sector central terminado.',
        ),
      ],
    );
    final centro = lote2.centro;
    _ubicaciones[ejecucion.id] = GeoPunto(
      centro.latitud + 0.0012,
      centro.longitud - 0.0009,
    );
    _mensajes[ejecucion.id] = [
      MensajeChat(
        id: 'm1',
        texto: 'Buen día. Empezamos por el lado oeste, el viento está calmo.',
        creadoEn: hace(const Duration(hours: 4)),
        propio: false,
      ),
      MensajeChat(
        id: 'm2',
        texto: 'Gracias por avisar. Mañana paso por el lote.',
        creadoEn: hace(const Duration(hours: 3, minutes: 40)),
        propio: true,
      ),
    ];
    _ofertas[ejecucion.id] = [
      OfertaRecibida(
        id: 'of-4102',
        solicitudId: ejecucion.id,
        numero: 2,
        autor: AutorOferta.cliente,
        precioHa: _d('118'),
        montoEstimado: ejecucion.hectareas * _d('118'),
        estado: EstadoOferta.aceptada,
        proveedor: ofertante(marcelo.id, drones[1 % drones.length]),
        creadaEn: hace(const Duration(days: 2, hours: 2)),
      ),
    ];

    // 3. Finalizada: el precio final espera al cliente.
    final lote3 = lotes[2];
    final fernando = datos.proveedorPorId('prov-fernando');
    final finalizada = base(
      '4103',
      lote3,
      lote3.hectareas,
      'Fungicida triazol + estrobilurina',
      _d('120'),
      EstadoSolicitud.finalizada,
      desde: hace(const Duration(days: 2)),
      acordado: _d('125'),
      ejecutadas: lote3.hectareas,
      porcentaje: _d('100'),
      montoFinal: lote3.hectareas * _d('125'),
      proveedorId: fernando.id,
      nombreProveedor: fernando.nombre,
      historial: [
        CambioEstado(
          estado: EstadoSolicitud.abierta,
          momento: hace(const Duration(days: 6)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.adjudicada,
          momento: hace(const Duration(days: 5)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.enEjecucion,
          momento: hace(const Duration(days: 2)),
        ),
        CambioEstado(
          estado: EstadoSolicitud.finalizada,
          momento: hace(const Duration(hours: 6)),
        ),
      ],
    );
    _solicitudes.add(finalizada);
    _avances[finalizada.id] = AvanceServicio(
      hectareasSolicitadas: finalizada.hectareas,
      hectareasEjecutadas: finalizada.hectareas,
      porcentaje: _d('100'),
      precioHaAcordado: _d('125'),
      montoFinal: finalizada.montoFinal,
      iniciadaEn: hace(const Duration(days: 2)),
      finalizadaEn: hace(const Duration(hours: 6)),
      fotos: [
        FotoAvance(
          id: 'f3',
          ruta: 'assets/imagenes/fondo_equipo_dron.jpg',
          subidaEn: hace(const Duration(hours: 7)),
          nota: 'Lote terminado.',
        ),
      ],
    );
    _mensajes[finalizada.id] = [
      MensajeChat(
        id: 'm3',
        texto: 'Terminamos. Subí las fotos del lote completo.',
        creadoEn: hace(const Duration(hours: 6)),
        propio: false,
      ),
    ];

    // 4. Calificada, en el historial.
    final lote4 = lotes[3];
    final daniela = datos.proveedorPorId('prov-daniela');
    _solicitudes.add(
      base(
        '4104',
        lote4,
        lote4.hectareas,
        'Herbicida de preemergencia',
        _d('100'),
        EstadoSolicitud.calificada,
        desde: hace(const Duration(days: 20)),
        acordado: _d('102'),
        ejecutadas: lote4.hectareas,
        porcentaje: _d('100'),
        montoFinal: lote4.hectareas * _d('102'),
        proveedorId: daniela.id,
        nombreProveedor: daniela.nombre,
        puntaje: 5,
        historial: [
          CambioEstado(
            estado: EstadoSolicitud.abierta,
            momento: hace(const Duration(days: 26)),
          ),
          CambioEstado(
            estado: EstadoSolicitud.adjudicada,
            momento: hace(const Duration(days: 24)),
          ),
          CambioEstado(
            estado: EstadoSolicitud.finalizada,
            momento: hace(const Duration(days: 19)),
          ),
          CambioEstado(
            estado: EstadoSolicitud.calificada,
            momento: hace(const Duration(days: 18)),
          ),
        ],
      ),
    );

    // 5. Expirada: nadie la tomó.
    _solicitudes.add(
      base(
        '4105',
        lotes[4],
        lotes[4].hectareas,
        'Fertilizante foliar',
        _d('60'),
        EstadoSolicitud.expirada,
        desde: hace(const Duration(days: 12)),
        historial: [
          CambioEstado(
            estado: EstadoSolicitud.abierta,
            momento: hace(const Duration(days: 15)),
          ),
          CambioEstado(
            estado: EstadoSolicitud.expirada,
            momento: hace(const Duration(days: 8)),
          ),
        ],
      ),
    );
    for (var i = 0; i < _solicitudes.length; i++) {
      _solicitudes[i] = _solicitudes[i].copiarCon(
        ofertasVigentes: _vigentes(_solicitudes[i].id),
      );
    }
  }
}
