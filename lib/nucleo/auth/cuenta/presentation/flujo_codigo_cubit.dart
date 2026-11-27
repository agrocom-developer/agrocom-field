import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/cuenta_seguridad.dart';

/// Dónde está la persona dentro de un flujo de código de un solo uso.
enum EtapaCodigo {
  /// Elige por dónde recibir el código.
  elegirCanal,

  /// Escribe los 6 dígitos (y, según el flujo, la contraseña nueva).
  escribirCodigo,

  /// Confirmado por el servidor.
  listo,
}

/// Valida el formato local del código; el servidor decide si es el correcto.
abstract final class ReglasCodigo {
  static const int largo = 6;

  static bool formatoValido(String? valor) =>
      RegExp(r'^\d{6}$').hasMatch((valor ?? '').trim());

  static String? validar(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe el código de 6 dígitos';
    if (!formatoValido(v)) return 'El código tiene 6 dígitos';
    return null;
  }
}

class FlujoCodigoEstado {
  const FlujoCodigoEstado({
    this.etapa = EtapaCodigo.elegirCanal,
    this.canal,
    this.destino,
    this.enviando = false,
    this.confirmando = false,
    this.reenvioEn = 0,
    this.limitado = false,
    this.canalesCaidos = const {},
    this.falla,
    this.resultado,
  });

  final EtapaCodigo etapa;
  final CanalCodigo? canal;

  /// Adónde fue el código, ya enmascarado por el servidor.
  final String? destino;
  final bool enviando;
  final bool confirmando;

  /// Segundos que faltan para poder pedir otro código (0 = ya se puede).
  final int reenvioEn;

  /// La espera viene de un `429` (la cuenta agotó sus códigos): ningún canal
  /// sirve hasta que termine. Si no, solo bloquea reenviar por el mismo canal.
  final bool limitado;

  /// Canales que el servidor dijo que no tiene configurados.
  final Set<CanalCodigo> canalesCaidos;
  final CuentaFalla? falla;

  /// Lo que devolvió la confirmación (el usuario, en la recuperación).
  final Object? resultado;

  bool get ocupado => enviando || confirmando;
  bool get puedeReenviar => reenvioEn == 0 && !ocupado;

  FlujoCodigoEstado copiarCon({
    EtapaCodigo? etapa,
    CanalCodigo? canal,
    String? Function()? destino,
    bool? enviando,
    bool? confirmando,
    int? reenvioEn,
    bool? limitado,
    Set<CanalCodigo>? canalesCaidos,
    CuentaFalla? Function()? falla,
    Object? Function()? resultado,
  }) => FlujoCodigoEstado(
    etapa: etapa ?? this.etapa,
    canal: canal ?? this.canal,
    destino: destino != null ? destino() : this.destino,
    enviando: enviando ?? this.enviando,
    confirmando: confirmando ?? this.confirmando,
    reenvioEn: reenvioEn ?? this.reenvioEn,
    limitado: limitado ?? this.limitado,
    canalesCaidos: canalesCaidos ?? this.canalesCaidos,
    falla: falla != null ? falla() : this.falla,
    resultado: resultado != null ? resultado() : this.resultado,
  );
}

/// El recorrido de «elegir canal, recibir el código y confirmarlo» que
/// comparten recuperar el acceso, cambiar la contraseña, verificar el
/// teléfono y eliminar la cuenta. Cada flujo inyecta qué pide y qué confirma.
///
/// - Si un canal responde `503 canal_no_disponible`, queda marcado y la
///   pantalla ofrece los otros sin culpar a la persona.
/// - Pedir otro código tiene una cuenta regresiva: la de `Retry-After` en un
///   `429` o [esperaReenvio] tras un envío exitoso.
class FlujoCodigoCubit extends Cubit<FlujoCodigoEstado> {
  FlujoCodigoCubit({
    required this.pedir,
    required this.confirmar,
    this.canales = CanalCodigo.values,
    this.esperaReenvio = const Duration(seconds: 30),
    this.esperaPorDefectoEn429 = const Duration(seconds: 60),
    this.paso = const Duration(seconds: 1),
  }) : super(const FlujoCodigoEstado());

  /// Pide el código por [canal]; devuelve a dónde fue, si el servidor lo dice.
  final Future<CodigoEnviado?> Function(CanalCodigo canal) pedir;

  /// Confirma el código; [contrasenaNueva] solo viaja en los flujos que la
  /// piden. Lo que devuelve queda en `resultado`.
  final Future<Object?> Function(String codigo, String? contrasenaNueva)
  confirmar;

  /// Canales que este flujo ofrece.
  final List<CanalCodigo> canales;
  final Duration esperaReenvio;
  final Duration esperaPorDefectoEn429;

  /// Cada cuánto baja un segundo la cuenta regresiva (las pruebas lo acortan).
  final Duration paso;

  Timer? _reloj;

  /// Canales que se pueden elegir ahora.
  List<CanalCodigo> get disponibles => [
    for (final c in canales)
      if (!state.canalesCaidos.contains(c)) c,
  ];

  Future<void> enviar(CanalCodigo canal) async {
    if (state.ocupado || (state.limitado && state.reenvioEn > 0)) return;
    emit(state.copiarCon(enviando: true, canal: canal, falla: () => null));
    try {
      final enviado = await pedir(canal);
      if (isClosed) return;
      emit(
        state.copiarCon(
          etapa: EtapaCodigo.escribirCodigo,
          enviando: false,
          destino: () => enviado?.destino,
        ),
      );
      _cuentaRegresiva(esperaReenvio.inSeconds, limitado: false);
    } on CuentaCanalNoDisponible catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          etapa: EtapaCodigo.elegirCanal,
          enviando: false,
          canalesCaidos: {...state.canalesCaidos, e.canal ?? canal},
          falla: () => e,
        ),
      );
    } on CuentaLimiteExcedido catch (e) {
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, falla: () => e));
      _cuentaRegresiva(
        (e.espera ?? esperaPorDefectoEn429).inSeconds,
        limitado: true,
      );
    } on CuentaFalla catch (e) {
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, falla: () => e));
    }
  }

  /// Pide otro código por el mismo canal (cuando la cuenta regresiva terminó).
  Future<void> reenviar() async {
    final canal = state.canal;
    if (canal == null || !state.puedeReenviar) return;
    await enviar(canal);
  }

  /// Vuelve a elegir canal («No me llegó, probar por otro medio»).
  void cambiarCanal() {
    if (state.ocupado) return;
    emit(state.copiarCon(etapa: EtapaCodigo.elegirCanal, falla: () => null));
  }

  Future<void> confirmarCodigo(String codigo, {String? contrasenaNueva}) async {
    if (state.ocupado) return;
    emit(state.copiarCon(confirmando: true, falla: () => null));
    try {
      final resultado = await confirmar(codigo.trim(), contrasenaNueva);
      if (isClosed) return;
      _reloj?.cancel();
      emit(
        state.copiarCon(
          etapa: EtapaCodigo.listo,
          confirmando: false,
          reenvioEn: 0,
          limitado: false,
          resultado: () => resultado,
        ),
      );
    } on CuentaFalla catch (e) {
      if (isClosed) return;
      emit(state.copiarCon(confirmando: false, falla: () => e));
    }
  }

  /// La persona volvió a escribir: se retira el aviso del intento anterior.
  void limpiarFalla() {
    if (state.falla == null) return;
    emit(state.copiarCon(falla: () => null));
  }

  void _cuentaRegresiva(int segundos, {required bool limitado}) {
    _reloj?.cancel();
    emit(state.copiarCon(reenvioEn: segundos, limitado: limitado));
    if (segundos <= 0) {
      emit(state.copiarCon(limitado: false));
      return;
    }
    _reloj = Timer.periodic(paso, (t) {
      if (isClosed) return t.cancel();
      final resto = state.reenvioEn - 1;
      emit(
        state.copiarCon(
          reenvioEn: resto < 0 ? 0 : resto,
          limitado: resto > 0 && state.limitado,
        ),
      );
      if (resto <= 0) t.cancel();
    });
  }

  @override
  Future<void> close() {
    _reloj?.cancel();
    return super.close();
  }
}
