import 'trabajo_asignado.dart';
import 'trabajo_en_curso.dart';

/// Por qué «Crear aplicación» no se puede usar sobre [trabajo] (tarea 27),
/// tal como lo lee el piloto; `null` si se puede. Dart puro, sin `drift`.
///
/// No cubre la orden que todavía no llegó (`TrabajoAsignado.puedeCrearAplicacion`):
/// ese caso ya tiene su propio aviso en la pantalla.
///
/// Con algo en curso en OTRO trabajo, no: el piloto vuelve a eso desde la
/// tarjeta de arriba y lo cierra primero — nunca dos sesiones abiertas a la
/// vez. Sobre el MISMO trabajo sí, porque lleva a la misma pantalla de
/// sesión, que arranca en la sesión que quedó abierta.
String? motivoCrearAplicacionBloqueado({
  required TrabajoAsignado trabajo,
  required TrabajoEnCurso? enCurso,
}) {
  if (enCurso != null && enCurso.trabajoUuidCliente != trabajo.uuidCliente) {
    return enCurso.conSesion
        ? 'Tenés una sesión en curso en otro trabajo: volvé a ella desde '
              '«Sesión en curso» y cerrala antes de crear otra aplicación.'
        : 'Tenés un trabajo en curso: volvé a él desde «Trabajo en curso» y '
              'cerralo antes de crear otra aplicación.';
  }
  return null;
}
