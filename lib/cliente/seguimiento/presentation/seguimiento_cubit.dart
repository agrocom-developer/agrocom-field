import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';

enum FaseSeguimiento { cargando, listo, noEncontrado, error }

class SeguimientoEstado {
  const SeguimientoEstado({
    required this.fase,
    this.solicitud,
    this.avance,
    this.ubicacion,
    this.sinConexion = false,
  });

  final FaseSeguimiento fase;
  final Solicitud? solicitud;
  final AvanceServicio? avance;

  /// La última ubicación del piloto; `null` si no reportó ninguna.
  final UbicacionPiloto? ubicacion;

  /// La última lectura falló por falta de red: se muestra lo último que
  /// llegó.
  final bool sinConexion;

  SeguimientoEstado copiarCon({
    FaseSeguimiento? fase,
    Solicitud? solicitud,
    AvanceServicio? avance,
    Object? ubicacion = _igual,
    bool? sinConexion,
  }) => SeguimientoEstado(
    fase: fase ?? this.fase,
    solicitud: solicitud ?? this.solicitud,
    avance: avance ?? this.avance,
    ubicacion: identical(ubicacion, _igual)
        ? this.ubicacion
        : ubicacion as UbicacionPiloto?,
    sinConexion: sinConexion ?? this.sinConexion,
  );
}

const _igual = Object();

/// Seguimiento simple de un servicio adjudicado: el avance con sus fotos y la
/// última ubicación del piloto. Vuelve a leer cada [intervalo] mientras la
/// pantalla está abierta; sin red conserva lo último que llegó (ADR 0017).
class SeguimientoCubit extends Cubit<SeguimientoEstado> {
  SeguimientoCubit({
    required SeguimientoRepositorio seguimiento,
    required SolicitudesRepositorio solicitudes,
    required this.solicitudId,
    Duration? intervalo = const Duration(seconds: 15),
  }) : _seguimiento = seguimiento,
       _solicitudes = solicitudes,
       super(const SeguimientoEstado(fase: FaseSeguimiento.cargando)) {
    if (intervalo != null) {
      _temporizador = Timer.periodic(intervalo, (_) => unawaited(_leer()));
    }
  }

  final SeguimientoRepositorio _seguimiento;
  final SolicitudesRepositorio _solicitudes;
  final String solicitudId;
  Timer? _temporizador;
  var _leyendo = false;

  Future<void> cargar() async {
    if (state.solicitud == null) {
      emit(const SeguimientoEstado(fase: FaseSeguimiento.cargando));
    }
    await _leer();
  }

  Future<void> _leer() async {
    if (isClosed || _leyendo) return;
    _leyendo = true;
    try {
      final solicitud = await _solicitudes.porId(solicitudId);
      if (isClosed) return;
      if (solicitud == null) {
        emit(state.copiarCon(fase: FaseSeguimiento.noEncontrado));
        return;
      }
      final avance = await _seguimiento.avance(solicitudId);
      // La ubicación solo existe mientras el servicio está en ejecución.
      final ubicacion = solicitud.estado == EstadoSolicitud.enEjecucion
          ? await _seguimiento.ubicacionDelPiloto(solicitudId)
          : null;
      if (isClosed) return;
      emit(
        SeguimientoEstado(
          fase: FaseSeguimiento.listo,
          solicitud: solicitud,
          avance: avance,
          ubicacion: ubicacion,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          // Con datos a la vista se conservan; solo se avisa.
          fase: state.solicitud == null
              ? FaseSeguimiento.error
              : FaseSeguimiento.listo,
          sinConexion: e is SinConexion,
        ),
      );
    } finally {
      _leyendo = false;
    }
  }

  Future<void> actualizar() => _leer();

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
