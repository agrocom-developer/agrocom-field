import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../conformidad/domain/conformidad_repositorio.dart';
import '../../problema/domain/problema_repositorio.dart';
import '../domain/servicios_cliente_repositorio.dart';

enum FaseDetalle { cargando, listo, noEncontrado, error }

class ServicioDetalleEstado {
  const ServicioDetalleEstado({
    required this.fase,
    this.servicio,
    this.expediente,
    this.problema,
    this.calificacion,
    this.sinConexion = false,
    this.anexosIncompletos = false,
  });

  final FaseDetalle fase;
  final Servicio? servicio;

  /// Acta y evidencias; nulo mientras cargan.
  final ExpedienteServicio? expediente;
  final ProblemaReportado? problema;
  final CalificacionEmitida? calificacion;
  final bool sinConexion;

  /// El servicio cargó, pero el acta, las evidencias o el problema no.
  final bool anexosIncompletos;

  ActaConformidad? get acta => expediente?.acta;

  List<HitoServicio> get hitos =>
      servicio == null ? const [] : lineaDeTiempo(servicio!, acta: acta);

  ServicioDetalleEstado copiarCon({
    FaseDetalle? fase,
    Servicio? servicio,
    ExpedienteServicio? expediente,
    ProblemaReportado? problema,
    CalificacionEmitida? calificacion,
    bool? sinConexion,
    bool? anexosIncompletos,
  }) => ServicioDetalleEstado(
    fase: fase ?? this.fase,
    servicio: servicio ?? this.servicio,
    expediente: expediente ?? this.expediente,
    problema: problema ?? this.problema,
    calificacion: calificacion ?? this.calificacion,
    sinConexion: sinConexion ?? this.sinConexion,
    anexosIncompletos: anexosIncompletos ?? this.anexosIncompletos,
  );
}

/// Detalle de un servicio: el servicio (en vivo, del repositorio), su
/// expediente, el problema reportado y la calificación emitida.
class ServicioDetalleCubit extends Cubit<ServicioDetalleEstado> {
  ServicioDetalleCubit({
    required ServiciosClienteRepositorio servicios,
    required ConformidadRepositorio conformidad,
    required ProblemaRepositorio problemas,
    required CalificacionRepositorio calificaciones,
    required this.servicioId,
  }) : _servicios = servicios,
       _conformidad = conformidad,
       _problemas = problemas,
       _calificaciones = calificaciones,
       super(const ServicioDetalleEstado(fase: FaseDetalle.cargando)) {
    _escuchar();
  }

  final ServiciosClienteRepositorio _servicios;
  final ConformidadRepositorio _conformidad;
  final ProblemaRepositorio _problemas;
  final CalificacionRepositorio _calificaciones;
  final String servicioId;
  StreamSubscription<List<Servicio>>? _suscripcion;

  void _escuchar() {
    _suscripcion?.cancel();
    try {
      _suscripcion = _servicios.observar().listen(
        _alCambiar,
        onError: _alFallar,
      );
    } on Object catch (e) {
      _alFallar(e);
    }
  }

  void _alCambiar(List<Servicio> lista) {
    Servicio? servicio;
    for (final s in lista) {
      if (s.id == servicioId) servicio = s;
    }
    if (servicio == null) {
      emit(const ServicioDetalleEstado(fase: FaseDetalle.noEncontrado));
      return;
    }
    emit(
      state.copiarCon(
        fase: FaseDetalle.listo,
        servicio: servicio,
        sinConexion: false,
      ),
    );
    unawaited(recargarAnexos());
  }

  void _alFallar(Object error) {
    if (isClosed) return;
    emit(
      state.copiarCon(
        fase: state.servicio == null ? FaseDetalle.error : FaseDetalle.listo,
        sinConexion: error is SinConexion,
      ),
    );
  }

  /// Vuelve a leer acta, evidencias, problema y calificación. Se llama al
  /// volver de firmar, de reportar o de calificar.
  Future<void> recargarAnexos() async {
    try {
      final expediente = await _conformidad.expediente(servicioId);
      final problema = await _problemas.delServicio(servicioId);
      final calificacion = await _calificaciones.emitida(servicioId);
      if (isClosed) return;
      emit(
        ServicioDetalleEstado(
          fase: state.fase,
          servicio: state.servicio,
          expediente: expediente,
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
    if (state.servicio == null) {
      emit(const ServicioDetalleEstado(fase: FaseDetalle.cargando));
      _escuchar();
    } else {
      emit(state.copiarCon(anexosIncompletos: false, sinConexion: false));
      unawaited(recargarAnexos());
    }
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
