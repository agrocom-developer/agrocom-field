import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/calificacion_repositorio.dart';

enum FaseCalificar { editando, enviando, enviada, error }

class CalificarEstado {
  const CalificarEstado({
    this.puntaje = 0,
    this.etiquetas = const {},
    this.comentario = '',
    this.fase = FaseCalificar.editando,
    this.sinConexion = false,
  });

  /// De 1 a 5; 0 mientras el cliente no eligió.
  final int puntaje;
  final Set<EtiquetaCalificacion> etiquetas;
  final String comentario;
  final FaseCalificar fase;

  /// El último envío falló por falta de red.
  final bool sinConexion;

  bool get puedeEnviar => puntaje > 0 && fase != FaseCalificar.enviando;

  CalificarEstado copiarCon({
    int? puntaje,
    Set<EtiquetaCalificacion>? etiquetas,
    String? comentario,
    FaseCalificar? fase,
    bool? sinConexion,
  }) => CalificarEstado(
    puntaje: puntaje ?? this.puntaje,
    etiquetas: etiquetas ?? this.etiquetas,
    comentario: comentario ?? this.comentario,
    fase: fase ?? this.fase,
    sinConexion: sinConexion ?? this.sinConexion,
  );
}

/// Calificación del cliente al proveedor: estrellas, etiquetas y comentario.
/// Dos toques alcanzan: una estrella y enviar.
class CalificarCubit extends Cubit<CalificarEstado> {
  CalificarCubit(this._repositorio, this.servicioId)
    : super(const CalificarEstado());

  final CalificacionRepositorio _repositorio;
  final String servicioId;

  static const largoMaximoComentario = 300;

  void elegirPuntaje(int puntaje) {
    if (state.fase == FaseCalificar.enviando) return;
    emit(
      state.copiarCon(
        puntaje: puntaje.clamp(1, 5),
        fase: FaseCalificar.editando,
      ),
    );
  }

  void alternarEtiqueta(EtiquetaCalificacion etiqueta) {
    if (state.fase == FaseCalificar.enviando) return;
    final nuevas = {...state.etiquetas};
    if (!nuevas.remove(etiqueta)) nuevas.add(etiqueta);
    emit(state.copiarCon(etiquetas: nuevas, fase: FaseCalificar.editando));
  }

  void cambiarComentario(String texto) {
    if (state.fase == FaseCalificar.enviando) return;
    emit(state.copiarCon(comentario: texto));
  }

  Future<void> enviar() async {
    if (!state.puedeEnviar) return;
    emit(state.copiarCon(fase: FaseCalificar.enviando, sinConexion: false));
    final comentario = state.comentario.trim();
    try {
      await _repositorio.calificarProveedor(
        servicioId: servicioId,
        puntaje: state.puntaje,
        etiquetas: state.etiquetas,
        comentario: comentario.isEmpty ? null : comentario,
      );
      if (isClosed) return;
      emit(state.copiarCon(fase: FaseCalificar.enviada));
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          fase: FaseCalificar.error,
          sinConexion: e is SinConexion,
        ),
      );
    }
  }
}
