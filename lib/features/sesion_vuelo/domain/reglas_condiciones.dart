import 'package:decimal/decimal.dart';

/// Reglas de dominio de las condiciones climáticas al abrir sesión (HU-06),
/// Dart puro (sin `drift`) — mismo criterio que `reglas_sesion.dart`: decidir
/// es responsabilidad de acá, escribir es responsabilidad del repositorio.
///
/// Umbrales exactos del contrato real (`docs/api/openapi.yaml` de
/// `agrocom-api`, `RegistroSync.observacion_agronomo`): viento > 17 km/h,
/// temperatura > 30°C, humedad > 90%. Fuera de eso, el registro no necesita
/// observación del agrónomo.
final _umbralVientoKmh = Decimal.parse('17');
final _umbralTemperaturaC = Decimal.parse('30');
final _umbralHumedadPct = Decimal.parse('90');

/// Se elige una excepción sellada, mismo criterio que
/// `TrabajoInexistenteExcepcion` (`reglas_sesion.dart`): una sola
/// precondición con un único modo de fallo, no un resultado sellado que
/// obligue a todo el árbol de llamadas a manejar un caso "éxito" envolvente.
/// `SesionRepository.abrirSesion` la lanza ANTES de escribir nada — ni
/// `SesionLocal` ni `CondicionLocal` ni `ColaSync` — porque el servidor va a
/// rechazar el registro completo igual (contrato explícito), y no tiene
/// sentido encolarlo para enterarse recién con señal.
class ObservacionAgronomoRequeridaExcepcion implements Exception {
  const ObservacionAgronomoRequeridaExcepcion();

  @override
  String toString() =>
      'ObservacionAgronomoRequeridaExcepcion: las condiciones están fuera de '
      'rango — observacion_agronomo y firma_observacion son obligatorias';
}

/// Decide si las mediciones caen fuera del rango operativo del contrato.
/// Función pura: no consulta nada, solo compara los tres valores contra los
/// umbrales fijos de arriba.
bool condicionesFueraDeRango({
  required Decimal vientoKmh,
  required Decimal temperaturaC,
  required Decimal humedadPct,
}) {
  return vientoKmh > _umbralVientoKmh ||
      temperaturaC > _umbralTemperaturaC ||
      humedadPct > _umbralHumedadPct;
}

/// Verifica la precondición "si está fuera de rango, `observacionAgronomo` y
/// `firmaObservacion` no pueden ser null ni vacíos" — lanza
/// [ObservacionAgronomoRequeridaExcepcion] si falla. [fueraDeRango] ya lo
/// resolvió el llamador con [condicionesFueraDeRango]; esta función no
/// vuelve a calcularlo, solo decide sobre el resultado.
///
/// Dentro de rango, la observación/firma son siempre válidas (incluso
/// ausentes) — el contrato no las exige en ese caso.
void verificarObservacionSiFueraDeRango({
  required bool fueraDeRango,
  required String? observacionAgronomo,
  required String? firmaObservacion,
}) {
  if (!fueraDeRango) return;

  final observacionPresente =
      observacionAgronomo != null && observacionAgronomo.trim().isNotEmpty;
  final firmaPresente =
      firmaObservacion != null && firmaObservacion.trim().isNotEmpty;

  if (!observacionPresente || !firmaPresente) {
    throw const ObservacionAgronomoRequeridaExcepcion();
  }
}
