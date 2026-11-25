import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../dominio/falla.dart';
import '../../foto_preparador.dart';
import '../pago_confirmado.dart';
import '../pagos_repositorio.dart';

enum FasePago { cargando, pendiente, confirmando, confirmado, error }

/// Por qué falló, para decirle a la persona qué hacer.
enum FalloPago { sinRed, soloTitular, rechazado, desconocido }

class PagoEstado {
  const PagoEstado({
    this.fase = FasePago.cargando,
    this.pago,
    this.metodo,
    this.fallo,
    this.mensaje,
    this.fallaAlLeer = false,
  });

  final FasePago fase;
  final PagoConfirmado? pago;

  /// Cómo lo recibió, si la persona lo indicó (opcional).
  final MetodoPago? metodo;
  final FalloPago? fallo;
  final String? mensaje;

  /// El error fue al leer si ya hay pago (no al confirmarlo).
  final bool fallaAlLeer;

  /// Solo el titular puede confirmar: repetir no ayuda.
  bool get sePuedeReintentar =>
      fase == FasePago.error && fallo != FalloPago.soloTitular;

  PagoEstado copiarCon({
    FasePago? fase,
    Object? pago = _igual,
    Object? metodo = _igual,
    Object? fallo = _igual,
    Object? mensaje = _igual,
    bool? fallaAlLeer,
  }) => PagoEstado(
    fase: fase ?? this.fase,
    pago: identical(pago, _igual) ? this.pago : pago as PagoConfirmado?,
    metodo: identical(metodo, _igual) ? this.metodo : metodo as MetodoPago?,
    fallo: identical(fallo, _igual) ? this.fallo : fallo as FalloPago?,
    mensaje: identical(mensaje, _igual) ? this.mensaje : mensaje as String?,
    fallaAlLeer: fallaAlLeer ?? this.fallaAlLeer,
  );
}

const _igual = Object();

/// «Ya recibí el pago» del proveedor titular (ADR 0020). En línea, sin
/// outbox: el `uuid_cliente` nace al abrir la acción y viaja en cada
/// reintento, de modo que repetir no duplica el pago. La app no cobra: solo
/// deja constancia de un pago hecho fuera.
class PagoCubit extends Cubit<PagoEstado> {
  PagoCubit(
    this._repositorio,
    this.solicitudId,
    this._l10n, {
    String? uuidCliente,
  }) : _uuid = uuidCliente ?? const Uuid().v4(),
       super(const PagoEstado());

  final PagosRepositorio _repositorio;
  final int solicitudId;
  final AppLocalizations _l10n;
  final String _uuid;

  /// Lee si el pago ya está confirmado.
  Future<void> cargar() async {
    emit(state.copiarCon(fase: FasePago.cargando, fallo: null, mensaje: null));
    try {
      final pago = await _repositorio.ver(solicitudId);
      if (isClosed) return;
      emit(
        pago == null
            ? state.copiarCon(fase: FasePago.pendiente, pago: null)
            : state.copiarCon(fase: FasePago.confirmado, pago: pago),
      );
    } on Object catch (e) {
      _fallar(e, cargando: true);
    }
  }

  void elegirMetodo(MetodoPago? metodo) {
    if (state.fase == FasePago.confirmando) return;
    emit(state.copiarCon(metodo: metodo));
  }

  /// Confirma que recibió el pago. Con un fallo, vuelve a llamarse con el
  /// mismo `uuid_cliente`.
  Future<void> confirmar() async {
    if (state.fase == FasePago.confirmando ||
        state.fase == FasePago.confirmado) {
      return;
    }
    emit(
      state.copiarCon(fase: FasePago.confirmando, fallo: null, mensaje: null),
    );
    try {
      final pago = await _repositorio.confirmar(
        solicitudId,
        uuidCliente: _uuid,
        metodo: state.metodo,
      );
      if (isClosed) return;
      emit(state.copiarCon(fase: FasePago.confirmado, pago: pago));
    } on OperacionRechazada catch (e) {
      if (e.motivo == MotivoPago.yaConfirmado) {
        // Otro registro ya lo confirmó: lo que importa es que quedó hecho.
        await cargar();
        return;
      }
      _fallar(e);
    } on Object catch (e) {
      _fallar(e);
    }
  }

  void _fallar(Object error, {bool cargando = false}) {
    if (isClosed) return;
    final f = describirFalla(
      error,
      l10n: _l10n,
      porDefecto: cargando
          ? _l10n.pagoNoPudimosRevisar
          : _l10n.pagoNoPudimosConfirmar,
    );
    final fallo = f.sinRed
        ? FalloPago.sinRed
        : error is OperacionRechazada
        ? (error.motivo == MotivoPago.soloTitular
              ? FalloPago.soloTitular
              : FalloPago.rechazado)
        : FalloPago.desconocido;
    emit(
      state.copiarCon(
        fase: FasePago.error,
        fallaAlLeer: cargando,
        fallo: fallo,
        mensaje: fallo == FalloPago.soloTitular
            ? _l10n.pagoSoloTitular
            : f.mensaje,
      ),
    );
  }
}
