import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Estado local de un trabajo, distinto del [EstadoSync] de `ColaSync`:
/// mismo criterio que `EstadoSesionLocal` de `sesion_local.dart` — no dice
/// si la fila ya sincronizó, dice si el trabajo sigue abierto en este
/// dispositivo.
enum EstadoTrabajoLocal { abierto, cerrado }

/// Espejo local de ESCRITURA de `AperturaTrabajo` MÁS los campos de
/// `CierreTrabajo` que aplican a ESTE trabajo (ver `AperturaTrabajo.php` y
/// `CierreTrabajo.php` en `agrocom-api`, contrato de `POST /api/sync`). A
/// diferencia de las tablas de catálogo (`OrdenCatalogo`, `LoteCatalogo`),
/// acá la identidad es [uuidCliente], generado en el dispositivo antes de
/// tocar la red (invariante 2 de CLAUDE.md): el trabajo puede no tener `id`
/// de servidor todavía cuando el piloto lo abre sin conectividad.
///
/// Apertura y cierre viven en la MISMA fila, mismo criterio que
/// `SesionLocal` (HU-09 llega después que la tabla original de HU-05, así
/// que estas columnas se agregan acá con `ALTER TABLE`, no con la creación
/// inicial de la tabla — ver la migración v6->v7 en `database.dart`).
@TableIndex(
  name: 'idx_trabajo_local_uuid_cliente_cierre',
  columns: {#uuidClienteCierre},
  unique: true,
)
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

  /// `abierto` hasta que el piloto decide cerrar el trabajo localmente
  /// (HU-09); recién ahí pasa a `cerrado`, en la misma transacción que
  /// completa los campos de cierre de abajo. Igual que
  /// `SesionLocal.estado`, es vocabulario local, no algo que el servidor
  /// confirme (invariante 7 de CLAUDE.md no aplica: esto no reescribe nada
  /// ya confirmado, es el modelo local de lo que el dispositivo propuso).
  TextColumn get estado => textEnum<EstadoTrabajoLocal>().withDefault(
    Constant(EstadoTrabajoLocal.abierto.name),
  )();

  /// Momento de cierre. `null` mientras [estado] sea `abierto`.
  DateTimeColumn get fin => dateTime().nullable()();

  /// Litros sobrantes al cerrar, opcional (espec §7.2 — el piloto puede no
  /// tener sobrante que declarar). Nunca `double` (invariante 9 de
  /// CLAUDE.md).
  TextColumn get litrosSobrante => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// `uuid_cliente` de una `EvidenciaLocal` con `tipo: 'imagen_campo'` ya
  /// subida — REQUERIDA para cerrar el trabajo ("sin captura no cierra",
  /// HU-09). Nullable a nivel de columna porque el trabajo nace sin ella
  /// (recién se completa al cierre); `TrabajoRepository.cerrarTrabajo`
  /// rechaza antes de escribir si no viene, mismo criterio que
  /// `IncidenciaLocal.evidenciaFotoUuidCliente`.
  TextColumn get evidenciaImagenCampoUuidCliente => text().nullable()();

  /// `uuid_cliente` del EVENTO de cierre — distinto de [uuidCliente] (que es
  /// el de apertura) — es el que se manda como `uuid_cliente` del registro
  /// `cierre_trabajo` en `ColaSync`. Único localmente por el mismo motivo
  /// que `SesionLocal.uuidClienteCierre`: no reencolar el mismo cierre dos
  /// veces. Sin `.unique()` acá a propósito: SQLite no permite agregar una
  /// columna UNIQUE con `ALTER TABLE ADD COLUMN` (verificado — lanza
  /// "Cannot add a UNIQUE column"), así que la unicidad se aplica con el
  /// índice [idxTrabajoLocalUuidClienteCierre] de más abajo, creado aparte
  /// en la misma migración.
  TextColumn get uuidClienteCierre => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
