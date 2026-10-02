import 'trabajo_en_curso.dart';

/// Un solo trabajo en curso por dispositivo (tareas 27 y 28): por qué no se
/// puede empezar algo sobre [trabajoUuidCliente] mientras [enCurso] sigue
/// abierto, tal como lo lee el piloto; `null` si se puede. Dart puro, sin
/// `drift`. La usan «Crear aplicación» en «Inicio», «Abrir trabajo» en el
/// detalle de orden y el propio `TrabajoRepository` antes de escribir.
///
/// [trabajoUuidCliente] es el trabajo sobre el que se quiere actuar; `null`
/// cuando se va a abrir uno nuevo, que siempre es OTRO. Sobre el MISMO
/// trabajo en curso no hay bloqueo: lleva a la misma pantalla de sesión, que
/// arranca en la sesión que quedó abierta.
///
/// [accion] completa el motivo («crear otra aplicación», «abrir otro
/// trabajo»).
String? motivoBloqueoPorEnCurso({
  required TrabajoEnCurso? enCurso,
  required String accion,
  String? trabajoUuidCliente,
}) {
  if (enCurso == null || enCurso.trabajoUuidCliente == trabajoUuidCliente) {
    return null;
  }
  return enCurso.conSesion
      ? 'Tenés una sesión en curso en otro trabajo: volvé a ella y cerrala '
            'antes de $accion.'
      : 'Tenés un trabajo en curso: volvé a él y cerralo antes de $accion.';
}
