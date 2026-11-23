import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../dominio/dominio.dart';
import '../domain/estado_red.dart';
import '../domain/ofertas_repositorio.dart';
import 'ofertas_estado.dart';

/// Bandeja de ofertas del proveedor.
///
/// Lleva el reloj de la cuenta regresiva, el estado de la red y las
/// respuestas en vuelo. Aceptar y rechazar van directo al repositorio (no
/// hay outbox: ADR 0009) con una clave de idempotencia por oferta que se
/// conserva entre reintentos, de modo que una respuesta perdida no se
/// convierte en dos.
class OfertasCubit extends Cubit<OfertasEstado> {
  OfertasCubit({
    required OfertasRepositorio repositorio,
    required EstadoRed estadoRed,
    DateTime Function() reloj = DateTime.now,
    String Function()? nuevaClave,
    Duration? pulso = const Duration(seconds: 1),
  }) : _repositorio = repositorio,
       _estadoRed = estadoRed,
       _reloj = reloj,
       _nuevaClave = nuevaClave ?? (() => const Uuid().v4()),
       _pulso = pulso,
       super(OfertasEstado(ahora: reloj()));

  final OfertasRepositorio _repositorio;
  final EstadoRed _estadoRed;
  final DateTime Function() _reloj;
  final String Function() _nuevaClave;

  /// Cada cuánto avanza la cuenta regresiva. `null` la deja en manos de
  /// quien llame a [tic] (pruebas).
  final Duration? _pulso;

  StreamSubscription<List<Oferta>>? _ofertasSub;
  StreamSubscription<bool>? _redSub;
  Timer? _temporizador;
  final _claves = <String, String>{};
  List<Oferta> _recibidas = const [];
  var _avisos = 0;

  void iniciar() {
    _redSub ??= _estadoRed.observar().listen((enLinea) {
      if (enLinea != state.enLinea) emit(state.copiarCon(enLinea: enLinea));
    });
    _suscribir();
    final pulso = _pulso;
    if (pulso != null) {
      _temporizador ??= Timer.periodic(pulso, (_) => tic());
    }
  }

  /// Vuelve a pedir la bandeja después de un error de carga.
  void reintentar() {
    emit(state.copiarCon(carga: CargaOfertas.cargando));
    _suscribir();
  }

  void _suscribir() {
    _ofertasSub?.cancel();
    _ofertasSub = _repositorio.observar().listen(
      (ofertas) {
        _recibidas = ofertas;
        _recalcular(carga: CargaOfertas.lista);
      },
      onError: (Object _) {
        if (!isClosed) emit(state.copiarCon(carga: CargaOfertas.error));
      },
    );
  }

  /// Avanza la cuenta regresiva al instante actual del reloj. Una oferta
  /// cuya ventana se agotó pasa a cerradas como vencida.
  void tic() {
    if (isClosed) return;
    _recalcular();
  }

  void _recalcular({CargaOfertas? carga}) {
    final ahora = _reloj();
    final vigentes = <Oferta>[];
    final cerradas = [...state.cerradas];
    for (final o in _recibidas) {
      if (o.restante(ahora) > Duration.zero) {
        vigentes.add(o);
      } else if (state.vigente(o.id) != null && state.cerrada(o.id) == null) {
        // Solo se cuenta como vencida la que el proveedor llegó a ver viva.
        cerradas.add(OfertaCerrada(o, MotivoCierreOferta.vencida));
      }
    }
    // Una oferta con la respuesta en vuelo sigue a la vista aunque la
    // bandeja ya no la traiga: la cierra el resultado, no la lectura.
    for (final o in state.ofertas) {
      if (state.respondiendo.contains(o.id) &&
          !_recibidas.any((r) => r.id == o.id)) {
        vigentes.add(o);
      }
    }
    vigentes.sort((a, b) => a.venceEn.compareTo(b.venceEn));
    emit(
      state.copiarCon(
        carga: carga,
        ofertas: vigentes,
        cerradas: cerradas,
        ahora: ahora,
      ),
    );
  }

  Future<void> aceptar(String ofertaId) => _responder(ofertaId, aceptar: true);

  Future<void> rechazar(String ofertaId) =>
      _responder(ofertaId, aceptar: false);

  Future<void> _responder(String ofertaId, {required bool aceptar}) async {
    final oferta = state.vigente(ofertaId);
    if (oferta == null || state.respondiendo.contains(ofertaId)) return;
    if (!state.enLinea) {
      _avisar(ResultadoRespuestaOferta.sinConexion, oferta);
      return;
    }
    emit(state.copiarCon(respondiendo: {...state.respondiendo, ofertaId}));
    final clave = _claves.putIfAbsent(ofertaId, _nuevaClave);
    ResultadoRespuestaOferta resultado;
    try {
      resultado = aceptar
          ? await _repositorio.aceptar(ofertaId, claveIdempotencia: clave)
          : await _repositorio.rechazar(ofertaId, claveIdempotencia: clave);
    } on Object {
      // La respuesta no llegó: la oferta sigue en la bandeja y el reintento
      // usa la misma clave.
      resultado = ResultadoRespuestaOferta.sinConexion;
    }
    if (isClosed) return;

    final motivo = switch (resultado) {
      ResultadoRespuestaOferta.perdida => MotivoCierreOferta.tomada,
      ResultadoRespuestaOferta.expirada => MotivoCierreOferta.vencida,
      _ => null,
    };
    final resuelta = resultado != ResultadoRespuestaOferta.sinConexion;
    if (resuelta) _claves.remove(ofertaId);
    emit(
      state.copiarCon(
        respondiendo: {...state.respondiendo}..remove(ofertaId),
        ofertas: resuelta
            ? [
                for (final o in state.ofertas)
                  if (o.id != ofertaId) o,
              ]
            : null,
        cerradas: motivo != null && state.cerrada(ofertaId) == null
            ? [...state.cerradas, OfertaCerrada(oferta, motivo)]
            : null,
      ),
    );
    if (resuelta) {
      _recibidas = [
        for (final o in _recibidas)
          if (o.id != ofertaId) o,
      ];
    }
    _avisar(resultado, oferta);
  }

  void _avisar(ResultadoRespuestaOferta resultado, Oferta oferta) {
    emit(state.copiarCon(aviso: AvisoRespuesta(++_avisos, resultado, oferta)));
  }

  /// Quita de la pantalla una oferta ya cerrada.
  void descartar(String ofertaId) {
    emit(
      state.copiarCon(
        cerradas: [
          for (final c in state.cerradas)
            if (c.oferta.id != ofertaId) c,
        ],
      ),
    );
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    _ofertasSub?.cancel();
    _redSub?.cancel();
    return super.close();
  }
}
