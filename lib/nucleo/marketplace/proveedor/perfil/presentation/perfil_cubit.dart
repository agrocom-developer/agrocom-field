import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/perfil_repositorio.dart';
import 'perfil_estado.dart';

/// Perfil del proveedor: datos, estado de aprobación, documentos,
/// auxiliares, métricas y calificaciones recibidas. Solo lectura: el alta y
/// la aprobación las resuelve un administrador en el panel web.
class PerfilCubit extends Cubit<PerfilEstado> {
  PerfilCubit(this._repositorio) : super(const PerfilCargando());

  final PerfilRepositorio _repositorio;

  Future<void> cargar() async {
    if (state is! PerfilCargando) emit(const PerfilCargando());
    try {
      final (proveedor, metricas, calificaciones, meses) = await (
        _repositorio.perfil(),
        _repositorio.metricas(),
        _repositorio.calificaciones(),
        _repositorio.hectareasPorMes(),
      ).wait;
      if (isClosed) return;
      emit(
        PerfilListo(
          proveedor: proveedor,
          metricas: metricas,
          calificaciones: calificaciones,
          hectareasPorMes: meses,
        ),
      );
    } on Object {
      if (!isClosed) emit(const PerfilError());
    }
  }
}
