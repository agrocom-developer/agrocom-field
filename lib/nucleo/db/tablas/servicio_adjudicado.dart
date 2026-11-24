import 'package:drift/drift.dart';

import '../../tipos/decimal_drift_converter.dart';

/// Espejo local de `servicios_asignados[]` de `GET /api/sync/catalogo`: la
/// solicitud que el servidor adjudicó al equipo y que se ejecuta sin red
/// (ADR 0016). Es lo que lee la UI del lote (invariante 1 de CLAUDE.md).
///
/// La fila la escribe el servidor; el dispositivo solo la espeja, con una
/// excepción: al marcar el inicio, el avance o el cierre sin señal, la app
/// actualiza `estado`, `hectareas_ejecutadas` y `porcentaje_avance` en la
/// misma transacción que encola el registro, para que la pantalla refleje lo
/// hecho. Mientras la solicitud tenga registros pendientes de subir, un pull
/// no pisa esos tres campos. Nunca se borra: un servicio retirado se oculta
/// (`oculto`), porque puede tener trabajo sin sincronizar.
class ServicioAdjudicado extends Table {
  /// Id de la solicitud en el servidor.
  IntColumn get id => integer()();

  TextColumn get uuidCliente => text()();

  /// `adjudicada`, `en_ejecucion` o `finalizada` (vocabulario del servidor,
  /// sin `textEnum`: lo valida y lo decide el servidor).
  TextColumn get estado => text()();

  TextColumn get tipoAplicacion => text()();

  TextColumn get hectareasSolicitadas =>
      text().map(const DecimalDriftConverter())();

  TextColumn get cultivo => text().nullable()();

  TextColumn get productoIndicado => text()();

  /// `cliente` o `proveedor`.
  TextColumn get aportaProducto => text()();

  /// Fechas `yyyy-MM-dd` de la ventana deseada.
  TextColumn get ventanaDesde => text()();

  TextColumn get ventanaHasta => text()();

  BoolColumn get urgente => boolean().withDefault(const Constant(false))();

  TextColumn get observaciones => text().nullable()();

  /// El `terreno` del catálogo tal cual llegó (JSON): nombre, hectáreas,
  /// polígono GeoJSON, accesos y colindantes sensibles.
  TextColumn get terrenoJson => text()();

  TextColumn get precioHaPropuesto => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get precioHaAcordado => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get hectareasEjecutadas => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  TextColumn get porcentajeAvance => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// Monto final congelado por el servidor al finalizar; hasta entonces la
  /// app muestra una estimación marcada como tal.
  TextColumn get montoFinal => text().nullable().map(
    NullAwareTypeConverter.wrap(const DecimalDriftConverter()),
  )();

  /// Nombre y teléfono del cliente: llegan solo tras adjudicar.
  TextColumn get contactoNombre => text().nullable()();

  TextColumn get contactoTelefono => text().nullable()();

  /// El servidor retiró el servicio (cancelado, reasignado o ejecutado): se
  /// oculta de la lista pero no se borra.
  BoolColumn get oculto => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
