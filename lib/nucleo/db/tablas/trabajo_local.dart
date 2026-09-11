import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de ESCRITURA de `AperturaTrabajo` (ver
/// `AperturaTrabajo.php` en `agrocom-api`, contrato de `POST /api/sync`).
/// A diferencia de las tablas de catálogo (`OrdenCatalogo`, `LoteCatalogo`),
/// acá la identidad es [uuidCliente], generado en el dispositivo antes de
/// tocar la red (invariante 2 de CLAUDE.md): el trabajo puede no tener `id`
/// de servidor todavía cuando el piloto lo abre sin conectividad.
///
/// Sin columnas de cierre ni columna de estado: "cerrar trabajo"
/// (`cierre_trabajo`) es una HU futura fuera de alcance de HU-05 (exige
/// evidencia que este esquema todavía no modela) y va a traer su propia
/// migración cuando llegue. Hasta entonces, "trabajo abierto" es simplemente
/// "existe la fila" — no hay un segundo valor de estado que distinguir
/// todavía, así que agregar una columna `estado` hoy sería diseñar para un
/// caso hipotético (CLAUDE.md pide no hacerlo).
class TrabajoLocal extends Table {
  /// Identidad del trabajo, generada en el dispositivo (invariante 2 de
  /// CLAUDE.md), nunca un id de servidor. Es la PK de la tabla (ver
  /// [primaryKey] más abajo) — eso ya le da unicidad local, evitando
  /// reencolar el mismo trabajo dos veces (ej. doble tap) antes incluso de
  /// llegar a la red.
  TextColumn get uuidCliente => text()();

  /// `OrdenCatalogo.id`: la orden SÍ existe ya en el servidor cuando el
  /// piloto la abre (llegó por el pull de catálogo de TE-06), a diferencia
  /// del trabajo y la sesión, que nacen en este dispositivo.
  IntColumn get ordenId => integer()();

  /// `OrdenCatalogo.loteId`, copiado a la apertura en vez de resuelto por
  /// join: el catálogo local puede haber rotado por un pull posterior, y el
  /// payload que se manda a `POST /api/sync` necesita el valor tal como
  /// estaba cuando el piloto abrió el trabajo.
  IntColumn get loteId => integer()();

  /// `OrdenCatalogo.nroAplicacion`, copiado por el mismo motivo que [loteId].
  IntColumn get nroAplicacion => integer()();

  /// Hectáreas: nunca `double` (invariante 9 de CLAUDE.md). El DTO del
  /// servidor la completa con `'0'` si no viene, pero acá el dispositivo la
  /// manda siempre con lo que tenga a la apertura — mismo default por
  /// consistencia con lo que el servidor asume ante ausencia.
  TextColumn get hectareasDeclaradas => text()
      .map(const DecimalDriftConverter())
      .withDefault(const Constant('0'))();

  /// Momento en que el piloto abrió el trabajo en este dispositivo.
  DateTimeColumn get inicio => dateTime()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
