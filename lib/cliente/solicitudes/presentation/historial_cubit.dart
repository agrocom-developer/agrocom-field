import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/solicitud.dart';
import '../domain/solicitudes_repositorio.dart';

enum FiltroHistorial { todos, activos, completados }

enum FaseHistorial { cargando, listo, error }

/// Hectáreas fumigadas en un mes, para el gráfico del historial.
class HectareasDelMes {
  const HectareasDelMes({required this.mes, required this.hectareas});

  /// Primer día del mes.
  final DateTime mes;
  final Decimal hectareas;
}

class HistorialEstado {
  const HistorialEstado({
    required this.fase,
    this.servicios = const [],
    this.filtro = FiltroHistorial.todos,
    this.sinConexion = false,
  });

  final FaseHistorial fase;

  /// Todas las solicitudes, de la más reciente a la más antigua.
  final List<Solicitud> servicios;
  final FiltroHistorial filtro;
  final bool sinConexion;

  List<Solicitud> get visibles => [
    for (final s in servicios)
      if (switch (filtro) {
        FiltroHistorial.todos => true,
        FiltroHistorial.activos => s.estado.activa,
        FiltroHistorial.completados =>
          s.estado == EstadoSolicitud.finalizada ||
              s.estado == EstadoSolicitud.calificada,
      })
        s,
  ];

  /// Las que ya terminaron el trabajo: finalizadas y calificadas.
  Iterable<Solicitud> get _completados => servicios.where(
    (s) =>
        s.estado == EstadoSolicitud.finalizada ||
        s.estado == EstadoSolicitud.calificada,
  );

  int get totalCompletados => _completados.length;

  /// Superficie fumigada en los servicios completados, decimal exacto.
  Decimal get hectareasFumigadas => _completados.fold(
    Decimal.zero,
    (a, s) => a + (s.hectareasEjecutadas ?? Decimal.zero),
  );

  /// Hectáreas fumigadas en cada uno de los últimos [meses] meses hasta
  /// [hasta], del más antiguo al más reciente. Los meses sin servicios van
  /// en cero para que el gráfico no salte.
  List<HectareasDelMes> hectareasPorMes({
    required DateTime hasta,
    int meses = 6,
  }) {
    final resultado = <HectareasDelMes>[];
    for (var i = meses - 1; i >= 0; i--) {
      final mes = DateTime(hasta.year, hasta.month - i);
      final suma = _completados
          .where(
            (s) =>
                s.ventanaDesde.year == mes.year &&
                s.ventanaDesde.month == mes.month,
          )
          .fold(
            Decimal.zero,
            (a, s) => a + (s.hectareasEjecutadas ?? Decimal.zero),
          );
      resultado.add(HectareasDelMes(mes: mes, hectareas: suma));
    }
    return resultado;
  }

  HistorialEstado copiarCon({
    FaseHistorial? fase,
    List<Solicitud>? servicios,
    FiltroHistorial? filtro,
    bool? sinConexion,
  }) => HistorialEstado(
    fase: fase ?? this.fase,
    servicios: servicios ?? this.servicios,
    filtro: filtro ?? this.filtro,
    sinConexion: sinConexion ?? this.sinConexion,
  );
}

/// Historial de solicitudes del cliente con un filtro simple.
class HistorialCubit extends Cubit<HistorialEstado> {
  HistorialCubit(this._repositorio)
    : super(const HistorialEstado(fase: FaseHistorial.cargando)) {
    _escuchar();
  }

  final SolicitudesRepositorio _repositorio;
  StreamSubscription<List<Solicitud>>? _suscripcion;

  void _escuchar() {
    _suscripcion?.cancel();
    try {
      _suscripcion = _repositorio.observar().listen(
        (lista) => emit(
          state.copiarCon(
            fase: FaseHistorial.listo,
            servicios: lista,
            sinConexion: false,
          ),
        ),
        onError: _alFallar,
      );
    } on Object catch (e) {
      _alFallar(e);
    }
  }

  void _alFallar(Object error) {
    if (isClosed) return;
    emit(
      state.copiarCon(
        // Con datos ya cargados se conserva lo último conocido.
        fase: state.servicios.isEmpty
            ? FaseHistorial.error
            : FaseHistorial.listo,
        sinConexion: error is SinConexion,
      ),
    );
  }

  void filtrar(FiltroHistorial filtro) => emit(state.copiarCon(filtro: filtro));

  void reintentar() {
    if (state.servicios.isEmpty) {
      emit(state.copiarCon(fase: FaseHistorial.cargando, sinConexion: false));
    }
    _escuchar();
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
