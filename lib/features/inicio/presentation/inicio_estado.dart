import '../domain/trabajo_asignado.dart';
import '../../sesion_vuelo/domain/trabajo_en_curso.dart';

/// Estado de `InicioCubit`: arranca `InicioCargando` y de ahí alterna entre
/// `InicioConTrabajo` y `InicioSinTrabajo` según cada emisión del stream —
/// el vacío es un estado explícito, nunca un trabajo inventado.
///
/// [enCurso] (tarea 27) viaja en los dos: lo que este dispositivo tiene en
/// curso no depende de que haya un trabajo asignado (puede estar retirado o
/// ser un trabajo abierto por la app).
sealed class InicioEstado {
  const InicioEstado();
}

final class InicioCargando extends InicioEstado {
  const InicioCargando();
}

final class InicioSinTrabajo extends InicioEstado {
  const InicioSinTrabajo({this.enCurso});

  final TrabajoEnCurso? enCurso;

  @override
  bool operator ==(Object other) =>
      other is InicioSinTrabajo && other.enCurso == enCurso;

  @override
  int get hashCode => enCurso.hashCode;
}

final class InicioConTrabajo extends InicioEstado {
  const InicioConTrabajo(this.trabajo, {this.enCurso});

  final TrabajoAsignado trabajo;
  final TrabajoEnCurso? enCurso;

  @override
  bool operator ==(Object other) =>
      other is InicioConTrabajo &&
      other.trabajo == trabajo &&
      other.enCurso == enCurso;

  @override
  int get hashCode => Object.hash(trabajo, enCurso);
}
