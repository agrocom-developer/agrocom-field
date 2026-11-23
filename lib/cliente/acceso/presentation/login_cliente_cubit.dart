import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/acceso_repositorio.dart';
import 'formulario_acceso_estado.dart';

/// Inicio de sesión del cliente. Requiere red: si no hay, el estado lo dice
/// y el formulario conserva lo escrito.
class LoginClienteCubit extends Cubit<FormularioAccesoEstado> {
  LoginClienteCubit(this._acceso) : super(const FormularioAccesoEstado());

  final AccesoRepositorio _acceso;

  Future<void> enviar({
    required String correo,
    required String contrasena,
  }) async {
    if (state.enviando) return;
    emit(const FormularioAccesoEstado(enviando: true));
    try {
      final sesion = await _acceso.iniciarSesion(
        correo: correo.trim(),
        contrasena: contrasena,
      );
      emit(FormularioAccesoEstado(sesion: sesion));
    } on AccesoExcepcion catch (e) {
      emit(FormularioAccesoEstado(fallo: e.motivo, porCampo: e.porCampo));
    } on Object {
      emit(const FormularioAccesoEstado(fallo: MotivoFalloAcceso.desconocido));
    }
  }

  /// La persona volvió a escribir: el aviso del intento anterior se retira.
  void limpiarFallo() {
    if (state.fallo == null && state.porCampo.isEmpty) return;
    emit(const FormularioAccesoEstado());
  }
}
