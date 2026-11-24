import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';

/// La solicitud no pudo salir porque el dispositivo no tiene conexión. El
/// formulario conserva lo escrito y el reintento reutiliza la misma clave de
/// idempotencia.
class SolicitudSinConexion implements Exception {
  const SolicitudSinConexion();
}

/// Solicitud de un servicio. Requiere red: no hay outbox en el flavor
/// cliente. La `claveIdempotencia` de [SolicitudServicio] se genera al abrir
/// el formulario y se reutiliza en cada reintento (ADR 0009).
abstract interface class SolicitudRepositorio {
  /// Lotes que el cliente tiene registrados.
  Future<List<Lote>> lotesDelCliente();

  /// Productos que el cliente suele aplicar, para elegir sin teclear.
  Future<List<String>> productosSugeridos();

  /// Cultivos habituales de la zona, para elegir sin teclear.
  Future<List<String>> cultivosSugeridos();

  /// Precio estimado. [hectareas] es la superficie a fumigar (por defecto la
  /// del lote) y [fechaDeseada] permite calcular el recargo por urgencia.
  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
    Decimal? hectareas,
    DateTime? fechaDeseada,
  });

  /// Crea el servicio. Lanza [SolicitudSinConexion] si no hay red.
  Future<Servicio> solicitar(SolicitudServicio solicitud);

  /// Avance de la asignación de un servicio recién solicitado: primero
  /// proveedores propios de Agrocom, después terceros de la zona.
  Stream<BusquedaProveedor> observarBusqueda(String servicioId);
}
