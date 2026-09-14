import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de ESCRITURA de `RegistroSync` con `tipo: "condiciones"` (ver
/// `docs/api/openapi.yaml` de `agrocom-api`, contrato de `POST /api/sync`):
/// las condiciones climáticas capturadas al abrir una sesión (HU-06). Es una
/// tabla propia, no columnas agregadas a [SesionLocal]: el catálogo `momento`
/// de la especificación ya deja la puerta abierta a más de un momento de
/// captura por sesión (hoy solo existe `inicio_sesion`), así que modelar esto
/// como 1:1 dentro de la sesión obligaría a otra migración el día que
/// aparezca un segundo `momento`.
class CondicionLocal extends Table {
  /// Identidad PROPIA de este registro de condiciones, generada en el
  /// dispositivo antes de tocar la red (invariante 2 de CLAUDE.md) — NO es el
  /// `uuid_cliente` de la sesión que abre. Es la PK de la tabla (ver
  /// [primaryKey] más abajo), que ya le da unicidad local y evita reencolar
  /// el mismo registro de condiciones dos veces.
  TextColumn get uuidCliente => text()();

  /// `uuid_cliente` de apertura de la [SesionLocal] referenciada — NUNCA un
  /// id de servidor. Referencia LÓGICA, sin FK física: mismo criterio que
  /// `SesionLocal.trabajoUuidCliente` con `TrabajoLocal`, acá por el mismo
  /// motivo (el orden de escritura entre tablas locales no se refuerza con FK
  /// en este esquema, no porque la sesión pueda faltar).
  TextColumn get sesionUuidCliente => text()();

  /// Catálogo cerrado del servidor (espec §4.3, hoy solo `inicio_sesion`).
  /// Sin `textEnum` a propósito, mismo criterio que `SesionLocal.motivoCierre`:
  /// ese catálogo lo valida y es dueño el servidor, no este dispositivo.
  TextColumn get momento => text()();

  /// Nunca `double` (invariante 9 de CLAUDE.md). A diferencia de
  /// `hectareasDeclaradas` de [TrabajoLocal]/[SesionLocal], SIN `withDefault`:
  /// las tres mediciones climáticas son siempre obligatorias (es una medición
  /// real tomada en el momento, no un valor que pueda faltar con sentido en
  /// `0`).
  TextColumn get vientoKmh => text().map(const DecimalDriftConverter())();

  /// Ídem [vientoKmh].
  TextColumn get temperaturaC => text().map(const DecimalDriftConverter())();

  /// Ídem [vientoKmh].
  TextColumn get humedadPct => text().map(const DecimalDriftConverter())();

  /// Obligatoria junto con [firmaObservacion] cuando alguna medición cae
  /// fuera de rango (viento > 17 km/h, temperatura > 30°C o humedad > 90%) —
  /// esa validación la aplica el servidor al recibir el registro, no este
  /// esquema.
  TextColumn get observacionAgronomo => text().nullable()();

  /// Texto plano por contrato explícito del servidor, no una captura gráfica
  /// real todavía (TE-07 aparte, fuera de alcance de esta migración).
  TextColumn get firmaObservacion => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
