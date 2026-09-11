/// Reglas de dominio de `sesion_vuelo`, Dart puro (sin `drift`): decidir es
/// responsabilidad de acá, consultar el estado local es responsabilidad del
/// repositorio (ADR 0005 de `agrocom-api` — domain no toca infraestructura).
///
/// Se elige una excepción sellada, no un resultado sellado tipo
/// `ResultadoLogin`: acá hay una sola precondición con un único modo de
/// fallo ("el trabajo no existe"), no varias respuestas nombradas de un
/// contrato de servidor que la UI necesite distinguir una por una. Una
/// excepción no capturada por el repositorio (se deja propagar) comunica
/// mejor "esto es un error del llamador, no debería pasar si la UI ya
/// validó que había un trabajo abierto" que un resultado que obligaría a
/// todo el árbol de llamadas a manejar un caso "éxito" envolvente.
///
/// No existe localmente un `Trabajo` con el `uuid_cliente` sobre el que se
/// intentó abrir una sesión. `SesionRepository.abrirSesion` la lanza ANTES
/// de escribir nada — ni `SesionLocal` ni `ColaSync`.
class TrabajoInexistenteExcepcion implements Exception {
  const TrabajoInexistenteExcepcion(this.trabajoUuidCliente);

  final String trabajoUuidCliente;

  @override
  String toString() =>
      'TrabajoInexistenteExcepcion: no existe un trabajo local con '
      'uuid_cliente=$trabajoUuidCliente';
}

/// Verifica la precondición "el trabajo existe" antes de abrir una sesión
/// (una sesión nunca vive sin su trabajo). [trabajoExiste] ya lo resolvió el
/// repositorio contra `drift` — esta función no toca infraestructura, solo
/// decide y, si corresponde, lanza [TrabajoInexistenteExcepcion].
void verificarTrabajoExiste({
  required bool trabajoExiste,
  required String trabajoUuidCliente,
}) {
  if (!trabajoExiste) {
    throw TrabajoInexistenteExcepcion(trabajoUuidCliente);
  }
}

/// Próxima `secuencia` de apertura de sesión dentro de un trabajo (empieza
/// en 1). Función pura: el repositorio le pasa la cantidad de sesiones
/// previas ya contada contra `drift` (`COUNT(*) WHERE trabajo_uuid_cliente
/// = X`).
int proximaSecuenciaSesion(int sesionesPrevias) => sesionesPrevias + 1;
