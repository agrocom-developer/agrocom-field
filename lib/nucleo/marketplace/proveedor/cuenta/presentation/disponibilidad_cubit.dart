import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../dominio/falla.dart';
import '../../negociacion/domain/negociacion.dart';
import '../../negociacion/domain/negociacion_repositorios.dart';
import '../domain/cuenta_proveedor.dart';

class DisponibilidadEstado {
  const DisponibilidadEstado({
    this.cargando = true,
    this.error = false,
    this.sinRed = false,
    this.propia,
    this.empresa,
    this.preferencias = const PreferenciasAviso(),
    this.cambiando = false,
    this.aviso,
  });

  final bool cargando;
  final bool error;
  final bool sinRed;
  final EstadoDisponibilidad? propia;
  final EstadoDisponibilidad? empresa;

  /// Parámetros de aviso del contrato vigente (solo lectura aquí; se editan
  /// en «Avisos»).
  final PreferenciasAviso preferencias;
  final bool cambiando;
  final String? aviso;

  /// La empresa está ocupada: tampoco recibes avisos aunque tú estés
  /// disponible.
  bool get empresaOcupada =>
      empresa != null && empresa!.valor != Disponibilidad.disponible;

  DisponibilidadEstado copiarCon({
    bool? cargando,
    bool? error,
    bool? sinRed,
    EstadoDisponibilidad? propia,
    EstadoDisponibilidad? empresa,
    PreferenciasAviso? preferencias,
    bool? cambiando,
    String? Function()? aviso,
  }) => DisponibilidadEstado(
    cargando: cargando ?? this.cargando,
    error: error ?? this.error,
    sinRed: sinRed ?? this.sinRed,
    propia: propia ?? this.propia,
    empresa: empresa ?? this.empresa,
    preferencias: preferencias ?? this.preferencias,
    cambiando: cambiando ?? this.cambiando,
    aviso: aviso != null ? aviso() : this.aviso,
  );
}

/// El interruptor de disponibilidad. Cambiarlo es una llamada en línea: sin
/// red no cambia y la pantalla lo dice (ADR 0023).
class DisponibilidadCubit extends Cubit<DisponibilidadEstado> {
  DisponibilidadCubit(this._repositorio, this._avisos, this._l10n)
    : super(const DisponibilidadEstado());

  final CuentaProveedorRepositorio _repositorio;

  /// Opcional: sin él no se muestran los parámetros de aviso.
  final AvisosRepositorio? _avisos;
  final AppLocalizations _l10n;

  Future<void> cargar() async {
    emit(state.copiarCon(cargando: true, error: false, sinRed: false));
    try {
      final cuenta = await _repositorio.estado();
      PreferenciasAviso? prefs;
      try {
        prefs = await _avisos?.leer();
      } on FallaMarketplace {
        // Los parámetros son un resumen: sin ellos la pantalla sigue útil.
      }
      if (isClosed) return;
      emit(
        state.copiarCon(
          cargando: false,
          propia: cuenta.disponibilidad,
          empresa: cuenta.disponibilidadEmpresa,
          preferencias: prefs,
        ),
      );
    } on SinConexion {
      if (!isClosed) {
        emit(state.copiarCon(cargando: false, error: true, sinRed: true));
      }
    } on OperacionRechazada {
      if (!isClosed) emit(state.copiarCon(cargando: false, error: true));
    }
  }

  Future<void> cambiar(Disponibilidad valor) async {
    final actual = state.propia;
    if (state.cambiando || actual == null || actual.valor == valor) return;
    emit(state.copiarCon(cambiando: true, aviso: () => null));
    try {
      final nueva = await _repositorio.cambiarDisponibilidad(valor);
      if (!isClosed) emit(state.copiarCon(cambiando: false, propia: nueva));
    } on SinConexion {
      if (!isClosed) {
        emit(
          state.copiarCon(
            cambiando: false,
            aviso: () => _l10n.disponibilidadSinRed,
          ),
        );
      }
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(state.copiarCon(cambiando: false, aviso: () => e.mensaje));
      }
    }
  }
}
