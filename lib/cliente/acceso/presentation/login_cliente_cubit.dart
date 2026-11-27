import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/acceso_repositorio.dart';
import 'formulario_acceso_estado.dart';

/// Inicio de sesión del cliente. Requiere red: si no hay, el estado lo dice
/// y el formulario conserva lo escrito. Tras un `429` el botón espera una
/// cuenta regresiva con los segundos de `Retry-After`.
class LoginClienteCubit extends Cubit<FormularioAccesoEstado> {
  LoginClienteCubit(
    this._acceso, {
    this.esperaPorDefecto = const Duration(seconds: 60),
    this.paso = const Duration(seconds: 1),
  }) : super(const FormularioAccesoEstado());

  final AccesoRepositorio _acceso;
  final Duration esperaPorDefecto;

  /// Cada cuánto baja un segundo la cuenta regresiva (las pruebas lo acortan).
  final Duration paso;
  Timer? _reloj;

  Future<void> enviar({
    required String usuario,
    required String contrasena,
  }) async {
    if (state.enviando || state.enEspera) return;
    emit(const FormularioAccesoEstado(enviando: true));
    try {
      final sesion = await _acceso.iniciarSesion(
        usuario: usuario.trim(),
        contrasena: contrasena,
      );
      emit(FormularioAccesoEstado(sesion: sesion));
    } on AccesoExcepcion catch (e) {
      if (isClosed) return;
      if (e.motivo == MotivoFalloAcceso.demasiadosIntentos) {
        _esperar(e.esperaSegundos ?? esperaPorDefecto.inSeconds);
        return;
      }
      emit(FormularioAccesoEstado(fallo: e.motivo, porCampo: e.porCampo));
    } on Object {
      emit(const FormularioAccesoEstado(fallo: MotivoFalloAcceso.desconocido));
    }
  }

  void _esperar(int segundos) {
    _reloj?.cancel();
    emit(
      FormularioAccesoEstado(
        fallo: MotivoFalloAcceso.demasiadosIntentos,
        esperaSegundos: segundos,
      ),
    );
    _reloj = Timer.periodic(paso, (t) {
      if (isClosed) return t.cancel();
      final resto = state.esperaSegundos - 1;
      if (resto <= 0) {
        t.cancel();
        emit(const FormularioAccesoEstado());
      } else {
        emit(
          FormularioAccesoEstado(
            fallo: MotivoFalloAcceso.demasiadosIntentos,
            esperaSegundos: resto,
          ),
        );
      }
    });
  }

  /// La persona volvió a escribir: el aviso del intento anterior se retira
  /// (salvo la espera de un `429`, que sigue contando).
  void limpiarFallo() {
    if (state.enEspera) return;
    if (state.fallo == null && state.porCampo.isEmpty) return;
    emit(const FormularioAccesoEstado());
  }

  @override
  Future<void> close() {
    _reloj?.cancel();
    return super.close();
  }
}
