import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Solicitud de un servicio. Requiere red: no hay outbox en el flavor
/// cliente. La `claveIdempotencia` de [SolicitudServicio] se genera al abrir
/// el formulario y se reutiliza en cada reintento (ADR 0009).
abstract interface class SolicitudRepositorio {
  /// Lotes que el cliente tiene registrados.
  Future<List<Lote>> lotesDelCliente();

  /// Productos que el cliente suele aplicar, para elegir sin teclear.
  Future<List<String>> productosSugeridos();

  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
  });

  Future<Servicio> solicitar(SolicitudServicio solicitud);
}
