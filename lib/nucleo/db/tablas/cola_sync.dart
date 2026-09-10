import 'package:drift/drift.dart';

/// Estados del patrón outbox (invariante 3 de CLAUDE.md; ver docs/vision.md,
/// "El protocolo de sincronización"). El motor de sync (`logica-offline`) es
/// quien mueve un registro de un estado a otro — acá solo se declara el
/// vocabulario. `confirmado`/`rechazado` los decide siempre el servidor,
/// nunca este dispositivo.
enum EstadoSync { pendiente, enviado, confirmado, rechazado }

/// Outbox local (ADR 0005 de `agrocom-api`): todo lo que el usuario escribe
/// se inserta en la tabla espejo de la feature y se encola acá en una sola
/// transacción (invariante 3 de CLAUDE.md). El motor de sync es quien lee y
/// avanza el estado de estas filas; este esquema solo deja el lugar listo.
///
/// A diferencia de las tablas del servidor, no lleva soft delete ni columnas
/// de auditoría completas (ADR 0007 de `agrocom-api` es convención del lado
/// servidor, que es la autoridad) — acá lo único que importa es si el
/// registro ya sincronizó.
class ColaSync extends Table {
  /// PK autoincremental local. No es el [uuidCliente]: esta columna no tiene
  /// significado fuera de este dispositivo.
  IntColumn get id => integer().autoIncrement()();

  /// Identidad generada en el dispositivo antes de tocar la red (invariante 2
  /// de CLAUDE.md), nunca en el servidor ni reutilizada entre reintentos.
  /// Única localmente: es lo que evita reencolar el mismo registro dos veces
  /// antes incluso de llegar a la red, y es la misma clave que el servidor
  /// usa para `UNIQUE (uuid_cliente)` del lado suyo.
  TextColumn get uuidCliente => text().unique()();

  /// Ej. `"trabajo"`, `"sesion"`, `"recarga"`. Todavía sin enum cerrado de
  /// valores posibles — cada feature define los suyos al aparecer.
  TextColumn get tipoEntidad => text()();

  /// JSON serializado del registro tal como se manda a `POST /api/sync`.
  TextColumn get payload => text()();

  /// Orden causal local (invariante 5 de CLAUDE.md): nunca se ordena un lote
  /// de sync por reloj de dispositivo, siempre por esta secuencia.
  IntColumn get secuencia => integer()();

  /// `pendiente → enviado → confirmado | rechazado`.
  TextColumn get estado =>
      textEnum<EstadoSync>().withDefault(Constant(EstadoSync.pendiente.name))();

  /// Se completa solo cuando el servidor responde `rechazado {motivo}`.
  TextColumn get motivoRechazo => text().nullable()();

  /// Diagnóstico y orden de lectura local únicamente — nunca decide orden
  /// causal entre dispositivos (eso es [secuencia]).
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}
