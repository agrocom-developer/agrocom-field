import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/conformidad_repositorio.dart';

enum FaseActa {
  cargando,

  /// El expediente está en pantalla.
  lista,

  /// La firma está viajando al servidor.
  firmando,

  /// El cliente acaba de firmar en esta pantalla.
  firmada,

  /// No se pudo cargar el expediente.
  error,
}

class ActaEstado {
  const ActaEstado({
    required this.fase,
    this.expediente,
    this.sinConexion = false,
    this.mensajeError,
  });

  final FaseActa fase;
  final ExpedienteServicio? expediente;
  final bool sinConexion;

  /// Falla de la firma, con el expediente todavía en pantalla.
  final String? mensajeError;

  ActaConformidad? get acta => expediente?.acta;
  List<EvidenciaServicio> get evidencias => expediente?.evidencias ?? const [];

  bool get puedeFirmar => fase == FaseActa.lista && (acta?.pendiente ?? false);
}

/// Evidencias y acta de un servicio; firma la conformidad del cliente.
class ActaCubit extends Cubit<ActaEstado> {
  ActaCubit(
    this._repositorio, {
    required this.servicioId,
    required this.claveIdempotencia,
  }) : super(const ActaEstado(fase: FaseActa.cargando)) {
    cargar();
  }

  final ConformidadRepositorio _repositorio;
  final String servicioId;

  /// Nace al abrir la pantalla y se reutiliza en cada reintento de firma.
  final String claveIdempotencia;

  Future<void> cargar() async {
    emit(const ActaEstado(fase: FaseActa.cargando));
    try {
      final expediente = await _repositorio.expediente(servicioId);
      if (isClosed) return;
      emit(ActaEstado(fase: FaseActa.lista, expediente: expediente));
    } on Object catch (e) {
      if (isClosed) return;
      emit(ActaEstado(fase: FaseActa.error, sinConexion: e is SinConexion));
    }
  }

  Future<void> firmar() async {
    if (!state.puedeFirmar) return;
    final expediente = state.expediente!;
    emit(ActaEstado(fase: FaseActa.firmando, expediente: expediente));
    try {
      final firmada = await _repositorio.firmar(
        servicioId: servicioId,
        claveIdempotencia: claveIdempotencia,
      );
      if (isClosed) return;
      emit(
        ActaEstado(
          fase: FaseActa.firmada,
          expediente: ExpedienteServicio(
            acta: firmada,
            evidencias: expediente.evidencias,
          ),
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        ActaEstado(
          fase: FaseActa.lista,
          expediente: expediente,
          sinConexion: e is SinConexion,
          mensajeError: switch (e) {
            SinConexion() =>
              'Sin conexión. Tu conformidad no se envió; probá de nuevo '
                  'cuando tengas señal.',
            OperacionRechazada(:final mensaje) => mensaje,
            _ => 'No pudimos registrar tu conformidad. Probá de nuevo.',
          },
        ),
      );
    }
  }
}
