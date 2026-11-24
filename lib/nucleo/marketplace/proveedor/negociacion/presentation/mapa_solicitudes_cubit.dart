import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dominio/dominio.dart';
import '../domain/avisador_solicitudes.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

enum EstadoMapa { cargando, listo, sinRed, error }

class MapaSolicitudesEstado {
  const MapaSolicitudesEstado({
    this.estado = EstadoMapa.cargando,
    this.filtros = const FiltrosMapa(),
    this.solicitudes = const [],
    this.zonas = const [],
    this.seleccionada,
    this.mensaje,
    this.hayMas = false,
    this.cargandoMas = false,
  });

  final EstadoMapa estado;
  final FiltrosMapa filtros;
  final List<SolicitudAbierta> solicitudes;
  final List<ResumenZona> zonas;

  /// La solicitud resaltada en el mapa y la lista.
  final int? seleccionada;
  final String? mensaje;
  final bool hayMas;
  final bool cargandoMas;

  MapaSolicitudesEstado copiarCon({
    EstadoMapa? estado,
    FiltrosMapa? filtros,
    List<SolicitudAbierta>? solicitudes,
    List<ResumenZona>? zonas,
    int? Function()? seleccionada,
    String? Function()? mensaje,
    bool? hayMas,
    bool? cargandoMas,
  }) => MapaSolicitudesEstado(
    estado: estado ?? this.estado,
    filtros: filtros ?? this.filtros,
    solicitudes: solicitudes ?? this.solicitudes,
    zonas: zonas ?? this.zonas,
    seleccionada: seleccionada != null ? seleccionada() : this.seleccionada,
    mensaje: mensaje != null ? mensaje() : this.mensaje,
    hayMas: hayMas ?? this.hayMas,
    cargandoMas: cargandoMas ?? this.cargandoMas,
  );

  int get totalSolicitudes => zonas.isEmpty
      ? solicitudes.length
      : zonas.fold(0, (a, z) => a + z.solicitudes);
}

/// El mapa de solicitudes abiertas: lectura en línea con filtros por zona,
/// hectáreas y precio. Al cargar, avisa con una notificación local si hay
/// solicitudes nuevas que encajan con las preferencias del piloto.
class MapaSolicitudesCubit extends Cubit<MapaSolicitudesEstado> {
  MapaSolicitudesCubit(
    this._mercado, {
    AvisadorSolicitudesNuevas? avisador,
    this.ubicacion,
  }) : _avisador = avisador,
       super(const MapaSolicitudesEstado());

  final MercadoRepositorio _mercado;
  final AvisadorSolicitudesNuevas? _avisador;

  /// Posición del piloto para ordenar por distancia, si la compartió.
  final ({double lat, double lon})? ubicacion;
  String? _cursor;

  Future<void> cargar() async {
    emit(state.copiarCon(estado: EstadoMapa.cargando, mensaje: () => null));
    await _consultar(state.filtros, avisar: true);
  }

  Future<void> aplicarFiltros(FiltrosMapa filtros) async {
    emit(
      state.copiarCon(
        filtros: filtros,
        estado: EstadoMapa.cargando,
        seleccionada: () => null,
      ),
    );
    await _consultar(filtros);
  }

  void seleccionar(int? id) => emit(state.copiarCon(seleccionada: () => id));

  Future<void> cargarMas() async {
    final cursor = _cursor;
    if (cursor == null || state.cargandoMas) return;
    emit(state.copiarCon(cargandoMas: true));
    try {
      final pagina = await _mercado.solicitudes(
        state.filtros,
        cursor: cursor,
        lat: ubicacion?.lat,
        lon: ubicacion?.lon,
      );
      _cursor = pagina.siguienteCursor;
      emit(
        state.copiarCon(
          solicitudes: [...state.solicitudes, ...pagina.solicitudes],
          hayMas: _cursor != null,
          cargandoMas: false,
        ),
      );
    } on FallaMarketplace {
      emit(state.copiarCon(cargandoMas: false));
    }
  }

  Future<void> _consultar(FiltrosMapa filtros, {bool avisar = false}) async {
    try {
      final resultados = await Future.wait([
        _mercado.solicitudes(filtros, lat: ubicacion?.lat, lon: ubicacion?.lon),
        _mercado.resumenZonas(filtros),
      ]);
      if (isClosed) return;
      final pagina = resultados[0] as PaginaSolicitudes;
      _cursor = pagina.siguienteCursor;
      emit(
        state.copiarCon(
          estado: EstadoMapa.listo,
          solicitudes: pagina.solicitudes,
          zonas: resultados[1] as List<ResumenZona>,
          hayMas: _cursor != null,
        ),
      );
      if (avisar) unawaited(_avisar());
    } on SinConexion {
      if (!isClosed) emit(state.copiarCon(estado: EstadoMapa.sinRed));
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(
          state.copiarCon(estado: EstadoMapa.error, mensaje: () => e.mensaje),
        );
      }
    }
  }

  /// El aviso local es un extra: si falla, el mapa no se entera.
  Future<void> _avisar() async {
    try {
      await _avisador?.revisar();
    } on Object {
      // Sin red o sin permiso de notificaciones: no es un error del mapa.
    }
  }
}
