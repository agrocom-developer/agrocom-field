import 'reglas_en_curso.dart';
import 'trabajo_en_curso.dart';

// Reglas de dominio de `trabajo` (HU-09, cierre de trabajo), Dart puro (sin
// `drift`): decidir es responsabilidad de acá, escribir es responsabilidad
// del repositorio — mismo criterio que `reglas_sesion.dart`/
// `reglas_condiciones.dart`.

/// No se proporcionó `evidenciaImagenCampoUuidCliente`, o vino vacío/solo
/// espacios, al cerrar un trabajo. El contrato real (`CierreTrabajo.php` en
/// `agrocom-api`) exige esa evidencia siempre — "sin captura no cierra".
/// `TrabajoRepository.cerrarTrabajo` la lanza ANTES de escribir nada — ni
/// `TrabajoLocal` ni `ColaSync` — porque el servidor va a rechazar el
/// registro completo igual (contrato explícito), mismo criterio que
/// `ObservacionAgronomoRequeridaExcepcion`.
class EvidenciaImagenCampoRequeridaExcepcion implements Exception {
  const EvidenciaImagenCampoRequeridaExcepcion();

  @override
  String toString() =>
      'EvidenciaImagenCampoRequeridaExcepcion: cerrar un trabajo exige '
      'evidencia_imagen_campo_uuid_cliente — "sin captura no cierra"';
}

/// Verifica la precondición "hay evidencia de imagen del campo" antes de
/// cerrar un trabajo — lanza [EvidenciaImagenCampoRequeridaExcepcion] si
/// [evidenciaImagenCampoUuidCliente] es `null` o está vacío/en blanco.
void verificarEvidenciaImagenCampo(String? evidenciaImagenCampoUuidCliente) {
  final vacia =
      evidenciaImagenCampoUuidCliente == null ||
      evidenciaImagenCampoUuidCliente.trim().isEmpty;
  if (vacia) {
    throw const EvidenciaImagenCampoRequeridaExcepcion();
  }
}

/// Ya hay algo en curso en este dispositivo — una sesión abierta o un
/// trabajo sin cerrar — y se intentó abrir OTRO trabajo (tarea 28): un solo
/// trabajo en curso a la vez. `TrabajoRepository.abrirTrabajo` y
/// `abrirTrabajoAsignado` la lanzan ANTES de escribir nada — ni
/// `TrabajoLocal` ni `ColaSync` —: la pantalla ya deshabilita el botón, pero
/// un doble toque o una pantalla vieja no pueden abrir dos.
class TrabajoEnCursoExcepcion implements Exception {
  const TrabajoEnCursoExcepcion(this.motivo);

  /// El motivo tal como lo lee el piloto (`motivoBloqueoPorEnCurso`).
  final String motivo;

  @override
  String toString() => 'TrabajoEnCursoExcepcion: $motivo';
}

/// Verifica que nada impida abrir [trabajoUuidCliente] (o uno nuevo, si es
/// `null`) con [enCurso] abierto — lanza [TrabajoEnCursoExcepcion] con el
/// motivo de `motivoBloqueoPorEnCurso`, la misma regla de las pantallas.
void verificarSinOtroTrabajoEnCurso({
  required TrabajoEnCurso? enCurso,
  String? trabajoUuidCliente,
}) {
  final motivo = motivoBloqueoPorEnCurso(
    enCurso: enCurso,
    trabajoUuidCliente: trabajoUuidCliente,
    accion: 'abrir otro trabajo',
  );
  if (motivo != null) throw TrabajoEnCursoExcepcion(motivo);
}
