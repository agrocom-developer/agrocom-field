import '../../sesion_vuelo/domain/reglas_en_curso.dart';
import '../../sesion_vuelo/domain/trabajo_en_curso.dart';
import 'trabajo_asignado.dart';

/// Por qué «Crear aplicación» no se puede usar sobre [trabajo] (tarea 27),
/// tal como lo lee el piloto; `null` si se puede. Dart puro, sin `drift`.
///
/// No cubre la orden que todavía no llegó (`TrabajoAsignado.puedeCrearAplicacion`):
/// ese caso ya tiene su propio aviso en la pantalla.
///
/// Con la orden pausada, no: el servidor aceptaría la sesión, pero el
/// dueño decidió que no se vuele sobre una orden pausada. Se habilita sola
/// cuando la orden vuelve a vigente (el pull la desmarca).
///
/// Con algo en curso en OTRO trabajo, no: el piloto vuelve a eso desde la
/// tarjeta de arriba y lo cierra primero. Es la regla compartida de
/// `motivoBloqueoPorEnCurso` (tarea 28), la misma de «Abrir trabajo».
String? motivoCrearAplicacionBloqueado({
  required TrabajoAsignado trabajo,
  required TrabajoEnCurso? enCurso,
}) {
  if (trabajo.ordenPausada) {
    return 'La orden de este trabajo está pausada: no se vuela hasta que '
        'vuelva a estar vigente.';
  }
  return motivoBloqueoPorEnCurso(
    enCurso: enCurso,
    trabajoUuidCliente: trabajo.uuidCliente,
    accion: 'crear otra aplicación',
  );
}
