import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/problema_repositorio.dart';

enum FaseReporte { editando, enviando, enviado, error }

class ReportarProblemaEstado {
  const ReportarProblemaEstado({
    this.motivo,
    this.detalle = '',
    this.fase = FaseReporte.editando,
    this.sinConexion = false,
    this.caso,
  });

  final MotivoProblema? motivo;
  final String detalle;
  final FaseReporte fase;
  final bool sinConexion;

  /// El caso que abrió soporte, una vez enviado.
  final ProblemaReportado? caso;

  bool get detalleValido =>
      detalle.trim().length >= ReportarProblemaCubit.largoMinimoDetalle;

  bool get puedeEnviar =>
      motivo != null && detalleValido && fase != FaseReporte.enviando;

  ReportarProblemaEstado copiarCon({
    MotivoProblema? motivo,
    String? detalle,
    FaseReporte? fase,
    bool? sinConexion,
    ProblemaReportado? caso,
  }) => ReportarProblemaEstado(
    motivo: motivo ?? this.motivo,
    detalle: detalle ?? this.detalle,
    fase: fase ?? this.fase,
    sinConexion: sinConexion ?? this.sinConexion,
    caso: caso ?? this.caso,
  );
}

/// Reporte de un problema con un servicio: motivo de un catálogo cerrado y
/// un detalle escrito por el cliente.
class ReportarProblemaCubit extends Cubit<ReportarProblemaEstado> {
  ReportarProblemaCubit(
    this._repositorio, {
    required this.servicioId,
    required this.claveIdempotencia,
  }) : super(const ReportarProblemaEstado());

  final ProblemaRepositorio _repositorio;
  final String servicioId;

  /// Nace al abrir el formulario y se reutiliza en cada reintento.
  final String claveIdempotencia;

  static const largoMinimoDetalle = 10;
  static const largoMaximoDetalle = 500;

  void elegirMotivo(MotivoProblema motivo) {
    if (state.fase == FaseReporte.enviando) return;
    emit(state.copiarCon(motivo: motivo, fase: FaseReporte.editando));
  }

  void cambiarDetalle(String texto) {
    if (state.fase == FaseReporte.enviando) return;
    emit(state.copiarCon(detalle: texto));
  }

  Future<void> enviar() async {
    if (!state.puedeEnviar) return;
    emit(state.copiarCon(fase: FaseReporte.enviando, sinConexion: false));
    try {
      final caso = await _repositorio.reportar(
        ReporteProblema(
          servicioId: servicioId,
          motivo: state.motivo!,
          detalle: state.detalle.trim(),
          claveIdempotencia: claveIdempotencia,
        ),
      );
      if (isClosed) return;
      emit(state.copiarCon(fase: FaseReporte.enviado, caso: caso));
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(fase: FaseReporte.error, sinConexion: e is SinConexion),
      );
    }
  }
}
