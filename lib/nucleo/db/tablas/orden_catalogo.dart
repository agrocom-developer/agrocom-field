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
  /// Simplificación deliberada: la UI de lista/detalle sigue mostrando un
  /// solo lote — soporte real multi-lote queda para HU-92 (lado app),
  /// planificada aparte. Se conserva porque `TrabajoLocal.loteId` lo copia al
  /// abrir trabajo; [cantidadLotes] y [hectareasSolicitadas] dicen cuánto de
  /// la orden queda fuera de este lote.
  IntColumn get loteId => integer()();

  /// `lotes.length` del contrato (TE-23, v10): con ADR 0022 de `agrocom-api`
  /// `lotes` es la copia de TODOS los lotes del contrato, así que una orden
  /// puede cubrir más de uno aunque [loteId] guarde solo el primero. Sirve
  /// para no presentar el lote de [loteId] como si fuera la orden entera.
  ///
  /// Nullable solo por la migración v9→v10 (`ALTER TABLE`, conserva las
  /// filas): una fila anterior queda en `null` hasta que el próximo pull
  /// —con el cursor reseteado por esa misma migración— la vuelva a traer.
  /// El pull siempre la completa.
  IntColumn get cantidadLotes => integer().nullable()();

  /// Suma de `lotes[].hectareas_solicitadas` (TE-23, v10): las hectáreas de
  /// la orden completa — con ADR 0022, las de cada lote completo del
  /// contrato. Nunca `double` (invariante 9 de CLAUDE.md). Nullable por el
  /// mismo motivo que [cantidadLotes].
  TextColumn get hectareasSolicitadas => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

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

  // Sin límites climáticos ni parámetros de vuelo (v13, tarea 25): el
  // servidor los movió a `trabajos[]` y viven en `TrabajoCatalogo`. La
  // migración v13 quitó las ocho columnas que quedaban acá.

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

  // Retiro (v14, tarea 26, `agrocom-api` #313): la fila se MARCA, nunca se
  // borra — es espejo del servidor y puede volver (una orden `pausada` que
  // pasa a `vigente` llega otra vez en `ordenes[]` y se desmarca).
  // `motivoRetiro` en `null` = no retirada. Nullable las tres por la
  // migración (`ALTER TABLE`, conserva las filas).

  /// Para una orden: el `estado` de `ordenes_retiradas` (`pausada`,
  /// `consumida`, `cancelada`, `vencida`), o el motivo local `fuera_de_alcance` cuando el barrido completo
  /// (pull desde cursor vacío) terminó sin traerla — ver
  /// `CatalogoRepository`.
  TextColumn get motivoRetiro => text().nullable()();

  /// `updated_at` del servidor en la sección de retirados. `null` en el
  /// retiro local por barrido: ese no tiene momento del servidor.
  DateTimeColumn get retiroActualizadoEn => dateTime().nullable()();

  /// Si llegó en el barrido completo en curso. Solo tiene sentido mientras
  /// `CursorCatalogo.barridoEnCurso` es verdadero: al empezar el barrido se
  /// pone en `false` en todas las filas y cada upsert lo deja en `true`.
  BoolColumn get vistoEnBarrido => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
