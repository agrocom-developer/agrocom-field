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
