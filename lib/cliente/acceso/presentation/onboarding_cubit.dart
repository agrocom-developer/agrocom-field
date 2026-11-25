import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/acceso_repositorio.dart';

class OnboardingEstado {
  const OnboardingEstado({this.paso = 0, this.terminado = false});

  final int paso;
  final bool terminado;

  bool get esUltimo => paso == OnboardingCubit.pasos - 1;

  @override
  bool operator ==(Object other) =>
      other is OnboardingEstado &&
      other.paso == paso &&
      other.terminado == terminado;

  @override
  int get hashCode => Object.hash(paso, terminado);
}

/// Presentación inicial de tres pasos. Al terminar (o saltar) deja anotado
/// que ya se vio, para no repetirla.
class OnboardingCubit extends Cubit<OnboardingEstado> {
  OnboardingCubit(this._acceso) : super(const OnboardingEstado());

  static const int pasos = 3;

  final AccesoRepositorio _acceso;

  /// Avanza un paso; en el último, termina.
  Future<void> siguiente() async {
    if (state.terminado) return;
    if (state.esUltimo) return terminar();
    emit(OnboardingEstado(paso: state.paso + 1));
  }

  /// Salta a la pantalla [indice] (los puntos del carrusel, el deslizar y el
  /// autoavance). Fuera de rango no hace nada.
  void irA(int indice) {
    if (state.terminado || indice < 0 || indice >= pasos) return;
    if (indice == state.paso) return;
    emit(OnboardingEstado(paso: indice));
  }

  void anterior() {
    if (state.terminado || state.paso == 0) return;
    emit(OnboardingEstado(paso: state.paso - 1));
  }

  Future<void> terminar() async {
    if (state.terminado) return;
    try {
      await _acceso.marcarOnboardingVisto();
    } on Object {
      // Si no se pudo guardar, la presentación se repite en el próximo
      // arranque; no bloquea la entrada.
    }
    emit(OnboardingEstado(paso: state.paso, terminado: true));
  }
}
