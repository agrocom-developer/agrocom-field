import 'package:decimal/decimal.dart';

/// Reglas de dominio de las condiciones climáticas al abrir sesión (HU-06),
/// Dart puro (sin `drift`) — mismo criterio que `reglas_sesion.dart`: decidir
/// es responsabilidad de acá, escribir es responsabilidad del repositorio.
///
/// Espejo de `Operaciones/Dominio/LimitesEfectivos` de `agrocom-api`
/// (#309/#310, develop @ a47e5280): el servidor valida el registro
/// `condiciones` contra los límites EFECTIVOS del trabajo de la sesión. Si la
/// regla de acá no coincide con esa, el servidor rechaza sesiones que el
/// piloto ya cargó en campo, sin conectividad.
///
/// Defaults del sistema (`RegistroCondiciones::VIENTO_MAX_KMH`, etc.): solo
/// se usan como fallback, en el mismo caso que el servidor. Un límite que la
/// Orden de Trabajo dejó en blanco hereda el default. Un trabajo sin Orden de
/// Trabajo usa los defaults: es el caso de todo trabajo que abre la app con
/// `abrirTrabajo`, porque solo `CrearOrdenTrabajo` del panel fija
/// `orden_trabajo_id`.
final _defaultVientoMaxKmh = Decimal.parse('17');
final _defaultTemperaturaMaxC = Decimal.parse('30');
final _defaultHumedadMaxPct = Decimal.parse('90');

/// Límites contra los que se deciden las condiciones de apertura.
///
/// Viento, temperatura y humedad máxima siempre tienen valor: el propio o el
/// default. La humedad mínima no tiene default y solo se exige si la Orden
/// de Trabajo la fijó. Nunca `double` (invariante 9 de CLAUDE.md).
class LimitesCondiciones {
  const LimitesCondiciones._({
    required this.vientoMaxKmh,
    required this.temperaturaMaxC,
    required this.humedadMaxPct,
    this.humedadMinPct,
  });

  /// Sin ningún límite propio: solo los defaults del sistema
  /// (`LimitesEfectivos::porDefecto()`). Es lo que aplica el servidor a un
  /// trabajo sin Orden de Trabajo.
  factory LimitesCondiciones.porDefecto() => LimitesCondiciones.resolver();

  /// `LimitesEfectivos::resolver()`: cada argumento es el límite propio del
  /// trabajo (en la app, la fila de `trabajo_catalogo`), o `null` si no lo
  /// tiene, en cuyo caso hereda el default.
  factory LimitesCondiciones.resolver({
    Decimal? vientoMaxKmh,
    Decimal? temperaturaMaxC,
    Decimal? humedadMaxPct,
    Decimal? humedadMinPct,
  }) => LimitesCondiciones._(
    vientoMaxKmh: vientoMaxKmh ?? _defaultVientoMaxKmh,
    temperaturaMaxC: temperaturaMaxC ?? _defaultTemperaturaMaxC,
    humedadMaxPct: humedadMaxPct ?? _defaultHumedadMaxPct,
    humedadMinPct: humedadMinPct,
  );

  final Decimal vientoMaxKmh;
  final Decimal temperaturaMaxC;
  final Decimal humedadMaxPct;
  final Decimal? humedadMinPct;

  /// `LimitesEfectivos::admiteCondiciones()`: los topes son inclusivos (`<=`;
  /// igual al límite está dentro de rango), y la humedad mínima también
  /// (`>=`), solo si está fijada.
  bool admite({
    required Decimal vientoKmh,
    required Decimal temperaturaC,
    required Decimal humedadPct,
  }) {
    final minimo = humedadMinPct;
    return vientoKmh <= vientoMaxKmh &&
        temperaturaC <= temperaturaMaxC &&
        humedadPct <= humedadMaxPct &&
        (minimo == null || humedadPct >= minimo);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LimitesCondiciones &&
          other.vientoMaxKmh == vientoMaxKmh &&
          other.temperaturaMaxC == temperaturaMaxC &&
          other.humedadMaxPct == humedadMaxPct &&
          other.humedadMinPct == humedadMinPct);

  @override
  int get hashCode =>
      Object.hash(vientoMaxKmh, temperaturaMaxC, humedadMaxPct, humedadMinPct);
}

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

/// Decide si las mediciones caen fuera del rango que el servidor admite sin
/// observación del agrónomo: lo contrario de [LimitesCondiciones.admite].
/// Función pura, no consulta nada.
///
/// [limites] son los efectivos del trabajo de la sesión
/// (`SesionRepository.limitesCondiciones`). Sin ellos se usan los defaults
/// del sistema, que es lo que aplica el servidor a un trabajo sin Orden de
/// Trabajo.
bool condicionesFueraDeRango({
  required Decimal vientoKmh,
  required Decimal temperaturaC,
  required Decimal humedadPct,
  LimitesCondiciones? limites,
}) {
  return !(limites ?? LimitesCondiciones.porDefecto()).admite(
    vientoKmh: vientoKmh,
    temperaturaC: temperaturaC,
    humedadPct: humedadPct,
  );
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
