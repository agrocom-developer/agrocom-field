import '../../ordenes/domain/orden_vigente.dart';

/// Reglas de dominio de `avisos_locales`, Dart puro (sin `drift` ni
/// `flutter_local_notifications` acá): decidir qué órdenes son "nuevas" es
/// responsabilidad de acá, leer el stream de órdenes y el store de ids ya
/// notificados es responsabilidad de `data/` (mismo criterio de pureza que
/// `reglas_sesion.dart` de `sesion_vuelo`).
///
/// [OrdenVigente.id] es el `id` del servidor (no hay `uuid_cliente` en
/// `OrdenCatalogo`: es un catálogo de solo lectura que llega por sync, no
/// un registro que nace en el dispositivo), estable entre pulls sucesivos
/// — el identificador correcto para no repetir un aviso.
List<OrdenVigente> ordenesNuevas({
  required List<OrdenVigente> actuales,
  required Set<int> idsYaNotificados,
}) => actuales.where((orden) => !idsYaNotificados.contains(orden.id)).toList();
