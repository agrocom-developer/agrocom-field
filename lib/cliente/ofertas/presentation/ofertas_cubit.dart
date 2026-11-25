import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/oferta_recibida.dart';
import '../domain/ofertas_repositorio.dart';

enum FaseOfertas { cargando, lista, noEncontrada, error }

/// Cómo se ordenan las ofertas vigentes para compararlas.
enum OrdenOfertas { precio, calificacion, distancia }

/// Qué pasó con la última respuesta, para que la pantalla lo diga.
enum AvisoOfertas { contraofertaEnviada, rechazada, cambio, sinConexion, error }

class OfertasEstado {
  const OfertasEstado({
    required this.fase,
    this.solicitud,
    this.ofertas = const [],
    this.orden = OrdenOfertas.precio,
    this.sinConexion = false,
    this.respondiendo,
    this.aviso,
    this.mensajeAviso,
    this.adjudicada = false,
  });

  final FaseOfertas fase;
  final Solicitud? solicitud;
  final List<OfertaRecibida> ofertas;
  final OrdenOfertas orden;
  final bool sinConexion;

  /// Id de la oferta cuya respuesta viaja al servidor.
  final String? respondiendo;
  final AvisoOfertas? aviso;
  final String? mensajeAviso;

  /// El cliente eligió una oferta: la solicitud quedó adjudicada.
  final bool adjudicada;

  /// Las ofertas que siguen abiertas, en el orden elegido.
  List<OfertaRecibida> vigentes(DateTime ahora) {
    final lista = [
      for (final o in ofertas)
        if (o.vigenteA(ahora)) o,
    ];
    lista.sort(switch (orden) {
      OrdenOfertas.precio => (a, b) => a.precioHa.compareTo(b.precioHa),
      OrdenOfertas.calificacion => (a, b) => b.proveedor.calificacion.compareTo(
        a.proveedor.calificacion,
      ),
      OrdenOfertas.distancia =>
        (a, b) => (a.distanciaKm ?? Decimal.fromInt(9999)).compareTo(
          b.distanciaKm ?? Decimal.fromInt(9999),
        ),
    });
    return lista;
  }

  /// Las que ya no se pueden responder (cerradas, vencidas, retiradas).
  List<OfertaRecibida> cerradas(DateTime ahora) => [
    for (final o in ofertas)
      if (!o.vigenteA(ahora)) o,
  ];

  OfertasEstado copiarCon({
    FaseOfertas? fase,
    Solicitud? solicitud,
    List<OfertaRecibida>? ofertas,
    OrdenOfertas? orden,
    bool? sinConexion,
    Object? respondiendo = _igual,
    Object? aviso = _igual,
    Object? mensajeAviso = _igual,
    bool? adjudicada,
  }) => OfertasEstado(
    fase: fase ?? this.fase,
    solicitud: solicitud ?? this.solicitud,
    ofertas: ofertas ?? this.ofertas,
    orden: orden ?? this.orden,
    sinConexion: sinConexion ?? this.sinConexion,
    respondiendo: identical(respondiendo, _igual)
        ? this.respondiendo
        : respondiendo as String?,
    aviso: identical(aviso, _igual) ? this.aviso : aviso as AvisoOfertas?,
    mensajeAviso: identical(mensajeAviso, _igual)
        ? this.mensajeAviso
        : mensajeAviso as String?,
    adjudicada: adjudicada ?? this.adjudicada,
  );
}

const _igual = Object();

/// Ofertas recibidas por una solicitud: las compara y responde (aceptar,
/// contraofertar, rechazar). El servidor decide si cada acción procede; ante
/// un `409` el cubit recarga y lo explica (ADR 0016).
///
/// Con [intervalo] vuelve a leer las ofertas cada tanto mientras la pantalla
/// está abierta: llegan ofertas nuevas sin que el cliente tenga que tirar de
/// la pantalla.
class OfertasCubit extends Cubit<OfertasEstado> {
  OfertasCubit({
    required OfertasRepositorio ofertas,
    required SolicitudesRepositorio solicitudes,
    required this.solicitudId,
    Duration? intervalo = const Duration(seconds: 20),
    Uuid? uuid,
  }) : _ofertas = ofertas,
       _solicitudes = solicitudes,
       _uuid = uuid ?? const Uuid(),
       super(const OfertasEstado(fase: FaseOfertas.cargando)) {
    if (intervalo != null) {
      _temporizador = Timer.periodic(intervalo, (_) => unawaited(_leer()));
    }
  }

  final OfertasRepositorio _ofertas;
  final SolicitudesRepositorio _solicitudes;
  final String solicitudId;
  final Uuid _uuid;
  Timer? _temporizador;

  /// Una clave por contraoferta que se está escribiendo: un reintento tras
  /// perder la respuesta crea una sola oferta (ADR 0016).
  final _claves = <String, String>{};

  Future<void> cargar() async {
    emit(
      state.copiarCon(
        fase: state.solicitud == null ? FaseOfertas.cargando : state.fase,
        sinConexion: false,
      ),
    );
    await _leer();
  }

  Future<void> _leer() async {
    if (isClosed || state.respondiendo != null) return;
    try {
      final solicitud = await _solicitudes.porId(solicitudId);
      final ofertas = await _ofertas.deLaSolicitud(solicitudId);
      if (isClosed) return;
      if (solicitud == null) {
        emit(state.copiarCon(fase: FaseOfertas.noEncontrada));
        return;
      }
      emit(
        state.copiarCon(
          fase: FaseOfertas.lista,
          solicitud: solicitud,
          ofertas: ofertas,
          sinConexion: false,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          // Con ofertas ya a la vista se conservan; solo se avisa.
          fase: state.solicitud == null ? FaseOfertas.error : state.fase,
          sinConexion: e is SinConexion,
        ),
      );
    }
  }

  Future<void> actualizar() => _leer();

  void ordenar(OrdenOfertas orden) => emit(state.copiarCon(orden: orden));

  void descartarAviso() =>
      emit(state.copiarCon(aviso: null, mensajeAviso: null));

  // ── Respuestas ────────────────────────────────────────────────────────

  Future<void> aceptar(OfertaRecibida oferta) => _responder(
    oferta,
    () => _ofertas.aceptar(oferta.id),
    alTerminar: () => emit(state.copiarCon(adjudicada: true)),
  );

  Future<void> contraofertar(
    OfertaRecibida oferta,
    Decimal precioHa, {
    String? nota,
  }) => _responder(
    oferta,
    () => _ofertas.contraofertar(
      oferta.id,
      precioHa: precioHa,
      claveIdempotencia: _claves.putIfAbsent(
        '${oferta.id}|$precioHa',
        _uuid.v4,
      ),
      nota: nota,
    ),
    aviso: AvisoOfertas.contraofertaEnviada,
  );

  Future<void> rechazar(OfertaRecibida oferta) => _responder(
    oferta,
    () => _ofertas.rechazar(oferta.id),
    aviso: AvisoOfertas.rechazada,
  );

  Future<void> _responder(
    OfertaRecibida oferta,
    Future<void> Function() accion, {
    AvisoOfertas? aviso,
    void Function()? alTerminar,
  }) async {
    // Un segundo toque mientras viaja el primero no hace nada.
    if (state.respondiendo != null) return;
    emit(
      state.copiarCon(respondiendo: oferta.id, aviso: null, mensajeAviso: null),
    );
    try {
      await accion();
      if (isClosed) return;
      emit(state.copiarCon(respondiendo: null, aviso: aviso));
      alTerminar?.call();
      await _leer();
    } on OfertaCambio catch (e) {
      if (isClosed) return;
      // La oferta cambió mientras el cliente decidía: se explica y se
      // recarga para que vea lo que hay ahora.
      emit(
        state.copiarCon(
          respondiendo: null,
          aviso: AvisoOfertas.cambio,
          mensajeAviso: e.mensaje,
        ),
      );
      await _leer();
    } on SinConexion {
      if (isClosed) return;
      emit(
        state.copiarCon(respondiendo: null, aviso: AvisoOfertas.sinConexion),
      );
    } on OperacionRechazada catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          respondiendo: null,
          aviso: AvisoOfertas.error,
          mensajeAviso: e.mensaje,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
