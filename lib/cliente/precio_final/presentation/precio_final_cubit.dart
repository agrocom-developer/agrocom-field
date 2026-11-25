import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/precio_final.dart';
import '../domain/precio_final_repositorio.dart';

/// Estado del precio final en la pantalla del cliente.
class PrecioFinalEstado {
  const PrecioFinalEstado({
    this.precio,
    this.cargando = true,
    this.confirmando = false,
    this.fallo,
  });

  /// `null` mientras el piloto no cierre el precio.
  final PrecioFinal? precio;
  final bool cargando;
  final bool confirmando;

  /// Por qué no se pudo confirmar o leer: sin red o rechazado.
  final FalloPrecioFinal? fallo;

  PrecioFinalEstado copiarCon({
    Object? precio = _igual,
    bool? cargando,
    bool? confirmando,
    Object? fallo = _igual,
  }) => PrecioFinalEstado(
    precio: identical(precio, _igual) ? this.precio : precio as PrecioFinal?,
    cargando: cargando ?? this.cargando,
    confirmando: confirmando ?? this.confirmando,
    fallo: identical(fallo, _igual) ? this.fallo : fallo as FalloPrecioFinal?,
  );
}

const _igual = Object();

enum FalloPrecioFinal { sinConexion, rechazado, desconocido }

/// Lee el precio final y lo confirma. La lectura que falla no rompe la
/// pantalla: el ticket sigue mostrando lo de la solicitud y solo falta el
/// botón de confirmar.
class PrecioFinalCubit extends Cubit<PrecioFinalEstado> {
  PrecioFinalCubit(this._repositorio, this._solicitudId)
    : super(const PrecioFinalEstado());

  /// Sin repositorio (la app no lo provee) la pantalla muestra solo lo de la
  /// solicitud y no ofrece confirmar.
  final PrecioFinalRepositorio? _repositorio;
  final String _solicitudId;

  Future<void> cargar() async {
    final repositorio = _repositorio;
    if (repositorio == null) {
      emit(state.copiarCon(cargando: false));
      return;
    }
    emit(state.copiarCon(cargando: true, fallo: null));
    try {
      final p = await repositorio.ver(_solicitudId);
      if (!isClosed) emit(state.copiarCon(precio: p, cargando: false));
    } on SinConexion {
      if (!isClosed) {
        emit(
          state.copiarCon(cargando: false, fallo: FalloPrecioFinal.sinConexion),
        );
      }
    } on Object {
      if (!isClosed) {
        emit(
          state.copiarCon(cargando: false, fallo: FalloPrecioFinal.desconocido),
        );
      }
    }
  }

  /// Confirma el precio. Devuelve `true` si quedó confirmado.
  Future<bool> confirmar() async {
    final repositorio = _repositorio;
    if (repositorio == null || state.confirmando || state.precio == null) {
      return false;
    }
    emit(state.copiarCon(confirmando: true, fallo: null));
    try {
      final p = await repositorio.confirmar(_solicitudId);
      if (!isClosed) emit(state.copiarCon(precio: p, confirmando: false));
      return true;
    } on SinConexion {
      if (!isClosed) {
        emit(
          state.copiarCon(
            confirmando: false,
            fallo: FalloPrecioFinal.sinConexion,
          ),
        );
      }
    } on OperacionRechazada {
      if (!isClosed) {
        emit(
          state.copiarCon(
            confirmando: false,
            fallo: FalloPrecioFinal.rechazado,
          ),
        );
      }
    } on Object {
      if (!isClosed) {
        emit(
          state.copiarCon(
            confirmando: false,
            fallo: FalloPrecioFinal.desconocido,
          ),
        );
      }
    }
    return false;
  }
}
