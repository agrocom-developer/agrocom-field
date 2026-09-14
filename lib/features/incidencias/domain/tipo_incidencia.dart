/// Catálogo cerrado del servidor para `RegistroIncidencia.tipo_incidencia`
/// (HU-08, ver `RegistroIncidencia.php` en `agrocom-api`). Enum de DOMINIO
/// puro (sin `drift`) — a diferencia de la columna `IncidenciaLocal.tipo`
/// (TEXT plano, ver ese archivo), este enum SÍ valida los 6 valores del lado
/// cliente antes de escribir, la misma responsabilidad que
/// `condicionesFueraDeRango` cumple para `reglas_condiciones.dart`: decidir
/// acá, escribir en el repositorio.
///
/// Los 6 nombres del enum coinciden letra por letra con el valor que viaja
/// en el JSON — `.name` es directamente el `tipo_incidencia` del contrato,
/// sin tabla de conversión intermedia.
enum TipoIncidencia { caldo, esc, bateria, mecanica, clima, otro }
