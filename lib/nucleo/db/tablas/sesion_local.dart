import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Estado local de una sesión, distinto del [EstadoSync] de `ColaSync`: no
/// dice si la fila ya sincronizó, dice si la sesión sigue activa en este
/// dispositivo. La UI necesita mostrar "sesión activa" vs "sesión cerrada"
/// sin esperar confirmación del servidor (edición optimista de la propia
/// fila que este dispositivo generó — invariante 6 de CLAUDE.md no aplica
/// acá porque nada de esto reescribe algo que el servidor ya confirmó).
enum EstadoSesionLocal { abierta, cerrada }

/// Espejo local de ESCRITURA de `AperturaSesion` MÁS los campos de
/// `CierreSesion` que aplican a ESTA sesión (ver `AperturaSesion.php` y
/// `CierreSesion.php` en `agrocom-api`, contrato de `POST /api/sync`).
///
/// Apertura y cierre viven en la MISMA fila en vez de en una tabla separada
/// de eventos: el cierre es un evento nuevo con su propio `uuid_cliente`
/// ([uuidClienteCierre]) que se encola aparte en `ColaSync` con su propio
/// `tipo_entidad` (`cierre_sesion`), pero localmente no hay ningún caso de
/// uso que necesite leer un cierre sin su apertura — separarlos en dos
/// tablas solo agregaría un join que ningún query local pide todavía.
class SesionLocal extends Table {
  /// Identidad de LA APERTURA de la sesión, generada en el dispositivo
  /// (invariante 2 de CLAUDE.md). Es la PK de la tabla (ver [primaryKey] más
  /// abajo), que ya le da unicidad local.
  TextColumn get uuidCliente => text()();

  /// `uuid_cliente` del [TrabajoLocal] que contiene esta sesión — NUNCA un id
  /// de servidor: el trabajo puede no tener uno todavía si se abrió sin
  /// conectividad (mismo motivo que `AperturaSesion::$trabajoUuidCliente`
  /// del lado servidor).
  TextColumn get trabajoUuidCliente => text()();

  /// Orden de apertura dentro de ESE trabajo (empieza en 1). La calcula el
  /// dominio en otra etapa — acá solo se declara la columna.
  IntColumn get secuencia => integer()();

  /// `persona_id` de quien abre la sesión (invariante 4 de CLAUDE.md: la
  /// sesión la escribe el piloto).
  IntColumn get pilotoId => integer()();

  /// HU-07 (dupla auxiliar/dron). Siempre `null` hasta esa HU — la columna
  /// existe ya para no requerir otra migración cuando llegue.
  IntColumn get auxiliarId => integer().nullable()();

  /// HU-07, ídem [auxiliarId].
  IntColumn get dronId => integer().nullable()();

  /// Hectáreas declaradas A LA APERTURA. Nunca `double` (invariante 9 de
  /// CLAUDE.md). Mismo default `'0'` que [TrabajoLocal.hectareasDeclaradas]
  /// y por el mismo motivo.
  TextColumn get hectareasDeclaradas => text()
      .map(const DecimalDriftConverter())
      .withDefault(const Constant('0'))();

  /// HU-07. `null` hasta esa HU.
  TextColumn get hectareaInicialAcumulada => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// Momento en que se abrió la sesión.
  DateTimeColumn get inicio => dateTime()();

  /// `abierta` hasta que el dispositivo decide cerrarla localmente; recién
  /// ahí pasa a `cerrada`, en la misma transacción que completa los campos de
  /// cierre de abajo. Igual que `ColaSync.estado`, es vocabulario local, no
  /// algo que el servidor confirme.
  TextColumn get estado => textEnum<EstadoSesionLocal>().withDefault(
    Constant(EstadoSesionLocal.abierta.name),
  )();

  /// Momento de cierre. `null` mientras [estado] sea `abierta`.
  DateTimeColumn get fin => dateTime().nullable()();

  /// Catálogo cerrado del servidor (espec §4.3): `completado`,
  /// `relevo_piloto`, `cambio_dron`, `falla_equipo`, `clima`, `fin_jornada`,
  /// `otro`. Sin `textEnum` a propósito, a diferencia de [estado]: ese
  /// catálogo lo valida y es dueño el servidor (misma idea que
  /// `OrdenCatalogo.estado`, que tampoco usa `textEnum` client-side);
  /// replicarlo acá como enum Dart obligaría a mantener las dos listas
  /// sincronizadas para siempre, y la UI que arma este valor (otra etapa,
  /// fuera de esta migración) es quien decide de dónde sale la lista de
  /// opciones que le muestra al piloto.
  TextColumn get motivoCierre => text().nullable()();

  /// Hectáreas declaradas AL CIERRE — valor distinto de
  /// [hectareasDeclaradas] (que es el de apertura), nunca se reescribe una
  /// sobre la otra.
  TextColumn get hectareasDeclaradasCierre => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// Litros consumidos, opcional incluso al cerrar (ver
  /// `CierreSesion::$litrosConsumidos`): una sesión puede cerrarse sin haber
  /// rociado nada (ej. `falla_equipo` antes de empezar).
  TextColumn get litrosConsumidos => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// `uuid_cliente` del EVENTO de cierre — distinto de [uuidCliente] (que es
  /// el de la apertura) — es el que se manda como `uuid_cliente` del registro
  /// `cierre_sesion` en `ColaSync`. Único localmente por el mismo motivo que
  /// [uuidCliente]: no reencolar el mismo cierre dos veces.
  TextColumn get uuidClienteCierre => text().nullable().unique()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
