import 'proveedor.dart';

/// Etapa de la asignación tal como la ve el cliente: el servicio se ofrece
/// primero a los proveedores propios de Agrocom y después a terceros de la
/// zona, ampliando el radio.
enum FaseBusqueda { propios, terceros, asignado, sinProveedor }

/// Cuadro del avance de la búsqueda de proveedor de un servicio.
class BusquedaProveedor {
  const BusquedaProveedor({required this.fase, this.radioKm, this.proveedor});

  final FaseBusqueda fase;

  /// Radio en el que se ofrece a terceros, en kilómetros.
  final int? radioKm;

  /// Proveedor que aceptó, cuando [fase] es [FaseBusqueda.asignado].
  final Proveedor? proveedor;

  bool get terminada =>
      fase == FaseBusqueda.asignado || fase == FaseBusqueda.sinProveedor;
}
