import 'package:drift/drift.dart';

/// Tabla de una sola fila (`id` siempre `0`): persiste el cursor del pull de
/// catálogo entre reinicios de la app, para que el motor de sync
/// (`logica-offline`) sepa desde dónde continuar sin tener que traer todo el
/// catálogo de nuevo. El repositorio de catálogo hace siempre upsert con
/// `id: 0` — esta tabla solo deja el lugar listo.
class CursorCatalogo extends Table {
  /// El `withDefault(0)` es solo documental, no un atajo para omitir la
  /// columna al escribir: SQLite trata a una PK entera de una sola columna
  /// como alias del `rowid` (confirmado empíricamente, no solo por doc), así
  /// que un insert que *omite* `id` autoasigna un rowid nuevo en vez de usar
  /// el `DEFAULT` — el upsert del repositorio siempre debe pasar `id:
  /// Value(0)` explícito, nunca confiar en que quede en `0` solo.
  IntColumn get id => integer().withDefault(const Constant(0))();

  TextColumn get cursor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
