import 'package:drift/drift.dart';

/// Espejo local de ESCRITURA de `RegistroIncidencia` (HU-08, ver
/// `RegistroIncidencia.php` en `agrocom-api`, contrato de `POST
/// /api/sync`, `tipo: 'incidencia'`). El piloto la registra durante una
/// sesión activa; nunca se reescribe una vez creada (invariante 6 de
/// CLAUDE.md), una corrección sería un evento nuevo.
class IncidenciaLocal extends Table {
  /// Identidad DEL EVENTO incidencia, generada en el dispositivo antes de
  /// tocar la red (invariante 2 de CLAUDE.md). Es la PK de la tabla (ver
  /// [primaryKey] más abajo).
  TextColumn get uuidCliente => text()();

  /// `uuid_cliente` de APERTURA de la sesión activa — nunca id de servidor
  /// (mismo motivo que `SesionLocal.trabajoUuidCliente`): la sesión puede
  /// no tener id de servidor todavía si se abrió sin conectividad.
  TextColumn get sesionUuidCliente => text()();

  /// Catálogo cerrado del servidor (`caldo`, `esc`, `bateria`, `mecanica`,
  /// `clima`, `otro`). Sin `textEnum` a propósito, mismo criterio que
  /// `EvidenciaLocal.tipo`/`SesionLocal.motivoCierre`: ese catálogo lo
  /// valida y es dueño el servidor, no este dispositivo. [TipoIncidencia]
  /// (capa de dominio) es lo que valida los 6 valores del lado cliente.
  TextColumn get tipo => text()();

  /// Texto libre opcional.
  TextColumn get descripcion => text().nullable()();

  /// Cuándo ocurrió el evento — distinto del momento en que se termina de
  /// registrar en pantalla.
  DateTimeColumn get hora => dateTime()();

  /// `uuid_cliente` de una [EvidenciaLocal] con `tipo: 'foto_incidencia'`
  /// ya capturada — REQUERIDO: sin foto no hay incidencia (mismo espíritu
  /// que "sin captura no cierra" de HU-09). La captura y el encolado de la
  /// evidencia son responsabilidad de `EvidenciaRepository`, no de esta
  /// tabla.
  TextColumn get evidenciaFotoUuidCliente => text()();

  @override
  Set<Column> get primaryKey => {uuidCliente};
}
