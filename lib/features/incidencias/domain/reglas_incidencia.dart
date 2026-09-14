// Reglas de dominio de `incidencias` (HU-08), Dart puro (sin `drift`):
// decidir es responsabilidad de acá, consultar el estado local de la sesión
// es responsabilidad del repositorio (ADR 0005 de `agrocom-api` — domain no
// toca infraestructura), mismo criterio que
// `reglas_sesion.dart`/`reglas_condiciones.dart` de `sesion_vuelo`.

/// No existe localmente una sesión con el `uuid_cliente` sobre el que se
/// intentó registrar una incidencia. `IncidenciaRepository.registrarIncidencia`
/// la lanza ANTES de comprimir/persistir la foto — no tiene sentido gastar
/// la captura si la sesión no es válida (mismo criterio que
/// `TrabajoInexistenteExcepcion` en `sesion_vuelo`).
class SesionInexistenteExcepcion implements Exception {
  const SesionInexistenteExcepcion(this.sesionUuidCliente);

  final String sesionUuidCliente;

  @override
  String toString() =>
      'SesionInexistenteExcepcion: no existe una sesión local con '
      'uuid_cliente=$sesionUuidCliente';
}

/// La sesión existe localmente pero ya está cerrada — un evento puntual no
/// tiene sentido sobre una sesión que el piloto ya dio por terminada.
class SesionCerradaExcepcion implements Exception {
  const SesionCerradaExcepcion(this.sesionUuidCliente);

  final String sesionUuidCliente;

  @override
  String toString() =>
      'SesionCerradaExcepcion: la sesión uuid_cliente=$sesionUuidCliente ya '
      'está cerrada';
}

/// Verifica la precondición "la sesión existe y está abierta" antes de
/// registrar una incidencia. [sesionExiste]/[sesionAbierta] ya los resolvió
/// el repositorio contra `drift` — esta función no toca infraestructura,
/// solo decide y, si corresponde, lanza [SesionInexistenteExcepcion] o
/// [SesionCerradaExcepcion].
void verificarSesionActiva({
  required bool sesionExiste,
  required bool sesionAbierta,
  required String sesionUuidCliente,
}) {
  if (!sesionExiste) {
    throw SesionInexistenteExcepcion(sesionUuidCliente);
  }
  if (!sesionAbierta) {
    throw SesionCerradaExcepcion(sesionUuidCliente);
  }
}
