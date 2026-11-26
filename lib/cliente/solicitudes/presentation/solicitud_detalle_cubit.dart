import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../problema/domain/problema_repositorio.dart';
import '../domain/solicitud.dart';
import '../domain/solicitudes_repositorio.dart';

enum FaseDetalle { cargando, listo, noEncontrado, error }

/// Por qué no salió una acción del detalle (cambiar precio, cancelar,
/// renovar).
enum FalloAccion { sinConexion, rechazada }

class SolicitudDetalleEstado {
  const SolicitudDetalleEstado({
    required this.fase,
    this.solicitud,
    this.problema,
    this.calificacion,
    this.sinConexion = false,
    this.anexosIncompletos = false,
    this.enCurso = false,
    this.fallo,
    this.mensajeFallo,
  });

  final FaseDetalle fase;
  final Solicitud? solicitud;
  final ProblemaReportado? problema;
  final CalificacionEmitida? calificacion;
  final bool sinConexion;

  /// La solicitud cargó, pero la calificación o el reclamo no.
  final bool anexosIncompletos;

  /// Hay una acción viajando al servidor.
  final bool enCurso;
  final FalloAccion? fallo;
  final String? mensajeFallo;

  List<HitoSolicitud> get hitos =>
      solicitud == null ? const [] : lineaDeTiempo(solicitud!);

  SolicitudDetalleEstado copiarCon({
    FaseDetalle? fase,
    Solicitud? solicitud,
    ProblemaReportado? problema,
    CalificacionEmitida? calificacion,
    bool? sinConexion,
    bool? anexosIncompletos,
    bool? enCurso,
    Object? fallo = _igual,
    Object? mensajeFallo = _igual,
  }) => SolicitudDetalleEstado(
    fase: fase ?? this.fase,
    solicitud: solicitud ?? this.solicitud,
    problema: problema ?? this.problema,
    calificacion: calificacion ?? this.calificacion,
    sinConexion: sinConexion ?? this.sinConexion,
    anexosIncompletos: anexosIncompletos ?? this.anexosIncompletos,
    enCurso: enCurso ?? this.enCurso,
    fallo: identical(fallo, _igual) ? this.fallo : fallo as FalloAccion?,
    mensajeFallo: identical(mensajeFallo, _igual)
        ? this.mensajeFallo
        : mensajeFallo as String?,
  );
}

const _igual = Object();

/// Detalle de una solicitud: la solicitud (en vivo, del repositorio), la
/// calificación emitida y el reclamo abierto, más las acciones de la
/// negociación que el cliente puede hacer sobre ella.
class SolicitudDetalleCubit extends Cubit<SolicitudDetalleEstado> {
  SolicitudDetalleCubit({
    required SolicitudesRepositorio solicitudes,
    required ProblemaRepositorio problemas,
    required CalificacionRepositorio calificaciones,
    required this.solicitudId,
  }) : _solicitudes = solicitudes,
       _problemas = problemas,
       _calificaciones = calificaciones,
       super(const SolicitudDetalleEstado(fase: FaseDetalle.cargando)) {
    _escuchar();
  }

  final SolicitudesRepositorio _solicitudes;
  final ProblemaRepositorio _problemas;
  final CalificacionRepositorio _calificaciones;
  final String solicitudId;
  StreamSubscription<List<Solicitud>>? _suscripcion;

  void _escuchar() {
    _suscripcion?.cancel();
    try {
      _suscripcion = _solicitudes.observar().listen(
        _alCambiar,
        onError: _alFallar,
      );
    } on Object catch (e) {
      _alFallar(e);
    }
  }

  void _alCambiar(List<Solicitud> lista) {
    Solicitud? solicitud;
    for (final s in lista) {
      if (s.id == solicitudId) solicitud = s;
    }
    if (solicitud == null) {
      emit(const SolicitudDetalleEstado(fase: FaseDetalle.noEncontrado));
      return;
    }
    final cambioEstado = state.solicitud?.estado != solicitud.estado;
    emit(
      state.copiarCon(
        fase: FaseDetalle.listo,
        solicitud: solicitud,
        sinConexion: false,
      ),
    );
    if (cambioEstado) {
      unawaited(recargarAnexos());
    }
  }

  void _alFallar(Object error) {
    if (isClosed) return;
    emit(
      state.copiarCon(
        fase: state.solicitud == null ? FaseDetalle.error : FaseDetalle.listo,
        sinConexion: error is SinConexion,
      ),
    );
  }

  /// Vuelve a leer la calificación y el reclamo. Se llama al volver de
  /// calificar o de reportar.
  Future<void> recargarAnexos() async {
    final estado = state.solicitud?.estado;
    if (estado == null || !estado.terminada) return;
    try {
      final problema = await _problemas.delServicio(solicitudId);
      final calificacion = await _calificaciones.emitida(solicitudId);
      if (isClosed) return;
      emit(
        SolicitudDetalleEstado(
          fase: state.fase,
          solicitud: state.solicitud,
          problema: problema,
          calificacion: calificacion,
          sinConexion: state.sinConexion,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(anexosIncompletos: true, sinConexion: e is SinConexion),
      );
    }
  }

  void reintentar() {
    if (state.solicitud == null) {
      emit(const SolicitudDetalleEstado(fase: FaseDetalle.cargando));
      _escuchar();
    } else {
      emit(state.copiarCon(anexosIncompletos: false, sinConexion: false));
      unawaited(recargarAnexos());
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────

  Future<bool> cambiarPrecio(Decimal precioHa) =>
      _accion(() => _solicitudes.cambiarPrecio(solicitudId, precioHa));

  Future<bool> cancelar(String motivo) =>
      _accion(() => _solicitudes.cancelar(solicitudId, motivo));

  Future<bool> renovar() => _accion(() => _solicitudes.renovar(solicitudId));

  Future<bool> _accion(Future<void> Function() accion) async {
    if (state.enCurso) return false;
    emit(state.copiarCon(enCurso: true, fallo: null, mensajeFallo: null));
    try {
      await accion();
      if (isClosed) return true;
      emit(state.copiarCon(enCurso: false));
      return true;
    } on SinConexion {
      if (!isClosed) {
        emit(state.copiarCon(enCurso: false, fallo: FalloAccion.sinConexion));
      }
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(
          state.copiarCon(
            enCurso: false,
            fallo: FalloAccion.rechazada,
            mensajeFallo: e.mensaje,
          ),
        );
      }
    }
    return false;
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
