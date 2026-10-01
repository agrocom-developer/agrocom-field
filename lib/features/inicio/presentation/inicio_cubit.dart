import 'dart:async';

import 'package:bloc/bloc.dart';

import '../data/inicio_repository.dart';
import '../domain/trabajo_asignado.dart';
import '../domain/trabajo_en_curso.dart';
import 'inicio_estado.dart';

/// Adaptador delgado entre `InicioRepository` y la pantalla «Inicio» —
/// mismo criterio que `OrdenesCubit`: se suscribe a los `Stream` locales al
/// construirse y traduce cada emisión a un `InicioEstado`.
///
/// Son dos fuentes (tarea 27): el trabajo asignado y lo que el dispositivo
/// tiene en curso. El estado sale del trabajo asignado, como antes; lo que
/// está en curso se le suma con el último valor recibido, sin esperar a que
/// llegue — mientras tanto vale `null`, y el formulario de apertura vuelve
/// a mirar `drift` antes de dejar abrir una sesión.
class InicioCubit extends Cubit<InicioEstado> {
  InicioCubit(InicioRepository repositorio) : super(const InicioCargando()) {
    _suscripcion = repositorio.trabajoAsignado().listen(_alRecibirTrabajo);
    _suscripcionEnCurso = repositorio.enCurso().listen(_alRecibirEnCurso);
  }

  late final StreamSubscription<TrabajoAsignado?> _suscripcion;
  late final StreamSubscription<TrabajoEnCurso?> _suscripcionEnCurso;

  bool _trabajoRecibido = false;
  TrabajoAsignado? _trabajo;
  TrabajoEnCurso? _enCurso;

  void _alRecibirTrabajo(TrabajoAsignado? trabajo) {
    _trabajoRecibido = true;
    _trabajo = trabajo;
    _emitir();
  }

  void _alRecibirEnCurso(TrabajoEnCurso? enCurso) {
    _enCurso = enCurso;
    if (_trabajoRecibido) _emitir();
  }

  void _emitir() {
    final trabajo = _trabajo;
    emit(
      trabajo == null
          ? InicioSinTrabajo(enCurso: _enCurso)
          : InicioConTrabajo(trabajo, enCurso: _enCurso),
    );
  }

  @override
  Future<void> close() async {
    await _suscripcion.cancel();
    await _suscripcionEnCurso.cancel();
    return super.close();
  }
}
