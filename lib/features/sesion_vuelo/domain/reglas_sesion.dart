import 'package:decimal/decimal.dart';

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

/// El acumulado final que el piloto ingresó al cerrar (lo que muestra el RC
/// del dron en ese momento) es menor al acumulado inicial que había
/// registrado al abrir — dato mal ingresado, nunca un caso válido (el
/// acumulado del RC solo crece). HU-07, control de doble conteo
/// (especificación funcional/técnica §2, "si la misión de DJI se retoma...").
class AcumuladoFinalMenorQueInicialExcepcion implements Exception {
  const AcumuladoFinalMenorQueInicialExcepcion({
    required this.hectareaInicialAcumulada,
    required this.hectareaFinalAcumulada,
  });

  final Decimal hectareaInicialAcumulada;
  final Decimal hectareaFinalAcumulada;

  @override
  String toString() =>
      'AcumuladoFinalMenorQueInicialExcepcion: acumulado final '
      '($hectareaFinalAcumulada) menor al inicial '
      '($hectareaInicialAcumulada)';
}

/// Hectáreas reales de una sesión que arrancó en relevo (HU-07): cuando la
/// misión de DJI se retoma, el RC del segundo piloto muestra el acumulado
/// del LOTE completo, no el propio, así que las hectáreas de ESTA sesión son
/// la diferencia entre el acumulado final (al cerrar) y el inicial (el que
/// ya traía el RC al abrir, registrado aparte) — nunca le pide al piloto que
/// reste a mano bajo presión de campo.
///
/// Lanza [AcumuladoFinalMenorQueInicialExcepcion] si el resultado sería
/// negativo, ANTES de que el llamador escriba nada.
Decimal calcularHectareasDeCierrePorAcumulado({
  required Decimal hectareaInicialAcumulada,
  required Decimal hectareaFinalAcumulada,
}) {
  final diferencia = hectareaFinalAcumulada - hectareaInicialAcumulada;
  if (diferencia < Decimal.zero) {
    throw AcumuladoFinalMenorQueInicialExcepcion(
      hectareaInicialAcumulada: hectareaInicialAcumulada,
      hectareaFinalAcumulada: hectareaFinalAcumulada,
    );
  }
  return diferencia;
}
