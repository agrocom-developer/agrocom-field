import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/comparador_ofertas.dart';
import '../domain/oferta_recibida.dart';
import '../domain/ofertas_repositorio.dart';

enum FaseOfertas { cargando, lista, noEncontrada, error }

/// Qué pasó con la última respuesta, para que la pantalla lo diga.
enum AvisoOfertas {
  contraofertaEnviada,
  rechazada,
  cambio,
  sinConexion,
  error,

  /// Llegó una oferta que el cliente todavía no había visto.
  nuevaOferta,
}

class OfertasEstado {
  const OfertasEstado({
    required this.fase,
    this.solicitud,
    this.ofertas = const [],
    this.filtros = const FiltrosOfertas(),
    this.filtrando = false,
    this.sinConexion = false,
    this.respondiendo,
    this.aviso,
    this.mensajeAviso,
    this.adjudicada = false,
  });

  final FaseOfertas fase;
  final Solicitud? solicitud;
  final List<OfertaRecibida> ofertas;

  /// El orden y los filtros del comparador; los aplica el servidor.
  final FiltrosOfertas filtros;

  /// Se está leyendo la lista con otro orden o filtro.
  final bool filtrando;
  final bool sinConexion;

  /// Id de la oferta cuya respuesta viaja al servidor.
  final String? respondiendo;
  final AvisoOfertas? aviso;
  final String? mensajeAviso;

  /// El cliente eligió una oferta: la solicitud quedó adjudicada.
  final bool adjudicada;

  OrdenOfertas get orden => filtros.orden;

  /// Las ofertas que siguen abiertas, en el orden que devolvió el servidor.
  List<OfertaRecibida> vigentes(DateTime ahora) => [
    for (final o in ofertas)
      if (o.vigenteA(ahora)) o,
  ];

  /// Las que ya no se pueden responder (cerradas, vencidas, retiradas).
  List<OfertaRecibida> cerradas(DateTime ahora) => [
    for (final o in ofertas)
      if (!o.vigenteA(ahora)) o,
  ];

  OfertasEstado copiarCon({
    FaseOfertas? fase,
    Solicitud? solicitud,
    List<OfertaRecibida>? ofertas,
    FiltrosOfertas? filtros,
    bool? filtrando,
    bool? sinConexion,
    Object? respondiendo = _igual,
    Object? aviso = _igual,
    Object? mensajeAviso = _igual,
    bool? adjudicada,
  }) => OfertasEstado(
    fase: fase ?? this.fase,
    solicitud: solicitud ?? this.solicitud,
    ofertas: ofertas ?? this.ofertas,
    filtros: filtros ?? this.filtros,
    filtrando: filtrando ?? this.filtrando,
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

  /// Ofertas del piloto ya vistas: una distinta avisa que llegó una nueva.
  final _vistas = <String>{};
  bool _leyoUnaVez = false;

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
      final ofertas = await _ofertas.deLaSolicitud(
        solicitudId,
        filtros: state.filtros,
      );
      if (isClosed) return;
      if (solicitud == null) {
        emit(state.copiarCon(fase: FaseOfertas.noEncontrada));
        return;
      }
      final ids = {
        for (final o in ofertas)
          if (o.estado == EstadoOferta.vigente &&
              o.autor == AutorOferta.proveedor)
            o.id,
      };
      // Con filtros activos la lista cambia por el filtro, no por llegadas.
      final llegoNueva =
          _leyoUnaVez &&
          !state.filtros.hayFiltros &&
          ids.any((id) => !_vistas.contains(id));
      _vistas.addAll(ids);
      _leyoUnaVez = true;
      emit(
        state.copiarCon(
          fase: FaseOfertas.lista,
          solicitud: solicitud,
          ofertas: ofertas,
          filtrando: false,
          sinConexion: false,
          aviso: llegoNueva ? AvisoOfertas.nuevaOferta : state.aviso,
          mensajeAviso: llegoNueva ? null : state.mensajeAviso,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          filtrando: false,
          // Con ofertas ya a la vista se conservan; solo se avisa.
          fase: state.solicitud == null ? FaseOfertas.error : state.fase,
          sinConexion: e is SinConexion,
        ),
      );
    }
  }

  Future<void> actualizar() => _leer();

  /// Cambia el orden y los filtros del comparador y vuelve a leer la lista.
  Future<void> aplicarFiltros(FiltrosOfertas filtros) {
    if (filtros == state.filtros) return Future.value();
    emit(state.copiarCon(filtros: filtros, filtrando: true));
    return _leer();
  }

  Future<void> ordenar(OrdenOfertas orden) =>
      aplicarFiltros(state.filtros.copiarCon(orden: orden));

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
    String? justificacionPrecio,
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
      justificacionPrecio: justificacionPrecio,
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
