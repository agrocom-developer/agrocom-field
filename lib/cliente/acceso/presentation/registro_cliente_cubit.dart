import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/acceso_repositorio.dart';
import 'formulario_acceso_estado.dart';

/// Registro del cliente. Los errores por campo del servidor (`422`) quedan
/// en el estado para mostrarlos junto a cada campo.
class RegistroClienteCubit extends Cubit<FormularioAccesoEstado> {
  RegistroClienteCubit(this._acceso) : super(const FormularioAccesoEstado());

  final AccesoRepositorio _acceso;

  Future<void> enviar(DatosRegistroCliente datos) async {
    if (state.enviando) return;
    emit(const FormularioAccesoEstado(enviando: true));
    try {
      final sesion = await _acceso.registrar(datos);
      emit(FormularioAccesoEstado(sesion: sesion));
    } on AccesoExcepcion catch (e) {
      emit(FormularioAccesoEstado(fallo: e.motivo, porCampo: e.porCampo));
    } on Object {
      emit(const FormularioAccesoEstado(fallo: MotivoFalloAcceso.desconocido));
    }
  }

  /// Retira el error del servidor de [campo] cuando la persona lo corrige.
  void campoEditado(CampoAcceso campo) {
    if (state.enviando) return;
    if (state.fallo == null && !state.porCampo.containsKey(campo)) return;
    emit(
      FormularioAccesoEstado(
        porCampo: {
          for (final e in state.porCampo.entries)
            if (e.key != campo) e.key: e.value,
        },
      ),
    );
  }
}
