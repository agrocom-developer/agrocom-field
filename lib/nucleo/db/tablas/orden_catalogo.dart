import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de solo lectura de `GET /api/sync/catalogo`
/// (`obtenerCatalogoSincronizacion` en `agrocom-api`). El dispositivo nunca
/// crea una orden — por eso la PK es el `id` que asigna el servidor, no un
/// `uuid_cliente` (a diferencia de las tablas que sí escribe este
/// dispositivo, como `ColaSync`).
///
/// Sin FK hacia [LoteCatalogo]: el pull es incremental por cursor, así que
/// una orden nueva puede llegar en un lote donde su lote no viene (porque no
/// cambió desde el cursor anterior y ya sincronizó antes). Una FK estricta
/// rompería ese caso legítimo.
class OrdenCatalogo extends Table {
  IntColumn get id => integer()();

  IntColumn get contratoId => integer()();

  /// Primer lote de `OrdenCatalogo.lotes` del contrato real (HU-92, tarea 107
  /// de `agrocom-api`: una orden puede cubrir varios lotes de la propiedad,
  /// confirmado en vivo contra `GET /api/sync/catalogo` el 14/9/2026).
  /// Simplificación deliberada: hoy ningún dato real trae más de un lote por
  /// orden, y la UI de lista/detalle sigue asumiendo un solo lote — soporte
  /// real multi-lote queda para HU-92 (lado app), planificada aparte.
  IntColumn get loteId => integer()();

  IntColumn get nroAplicacion => integer()();

  /// Litros por hectárea si la categoría de insumo es líquida; `null` si es
  /// sólida (HU-79, tarea 110 de `agrocom-api` — mutuamente excluyente con
  /// [kilosPorVuelo], confirmado en vivo el 14/9/2026: antes de esto la
  /// columna era `NOT NULL` y el pull de catálogo tiraba en cualquier orden
  /// de insumo sólido, o directamente en cualquier orden hoy — el contrato
  /// real ya manda `litros_ha`/`kilos_por_vuelo` así). Dinero/hectáreas
  /// nunca en `double` (invariante 9 de CLAUDE.md).
  TextColumn get litrosHa => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// Kilos por vuelo si la categoría de insumo es sólida; `null` si es
  /// líquida — ver [litrosHa].
  TextColumn get kilosPorVuelo => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get humedadMinPct => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get vientoMaxKmh => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get temperaturaMaxC => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get humedadMaxPct => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get velocidadMaxKmh => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get alturaVueloM => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get velocidadVueloKmh => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get anchoPasadaM => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get observaciones => text().nullable()();

  IntColumn get emitidaPorContactoId => integer().nullable()();

  /// Viaja como `date` (solo fecha, ej. `"2026-08-26"`, sin hora). Texto
  /// simple a propósito: nadie hace aritmética de fecha con esto todavía, y
  /// así se evita que drift le aplique conversión de zona horaria a un valor
  /// que no la tiene.
  TextColumn get fechaEmision => text()();

  /// Valor libre tipo `"vigente"` — sin `textEnum` todavía porque no hay
  /// confirmado un conjunto cerrado de valores posibles.
  TextColumn get estado => text()();

  /// Campo que ordena el cursor de continuación del pull — tipado como
  /// `DateTime` (a diferencia de [fechaEmision]) porque sí viaja con offset
  /// y sí participa de comparaciones.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
