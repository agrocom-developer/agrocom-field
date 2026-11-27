import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitudes/domain/solicitud.dart';

/// La solicitud no pudo salir porque el dispositivo no tiene conexión. El
/// formulario conserva lo escrito y el reintento reutiliza la misma clave de
/// idempotencia.
class SolicitudSinConexion implements Exception {
  const SolicitudSinConexion();
}

/// Lo que el cliente declara para abrir su solicitud a los pilotos.
/// `claveIdempotencia` nace en el dispositivo al abrir el formulario para que
/// un reintento no cree dos solicitudes (ADR 0009).
class NuevaSolicitud {
  const NuevaSolicitud({
    required this.lote,
    required this.hectareas,
    required this.cultivo,
    required this.producto,
    required this.fechaDeseada,
    required this.precioHa,
    required this.claveIdempotencia,
    this.accesos,
    this.observaciones,
    this.contactoId,
    this.justificacionPrecio,
  });

  final Lote lote;
  final Decimal hectareas;
  final String cultivo;
  final String producto;
  final DateTime fechaDeseada;

  /// Precio por hectárea que propone el cliente.
  final Decimal precioHa;
  final String claveIdempotencia;

  /// Cómo se llega al lote; solo se guarda si el lote es nuevo.
  final String? accesos;
  final String? observaciones;

  /// Persona de contacto de un cliente empresa (`contacto_id` del contrato);
  /// `null` si el cliente es una persona o no eligió.
  final int? contactoId;

  /// Por qué el cliente propone ese precio (opcional, hasta 500
  /// caracteres); el piloto lo lee antes de ofertar.
  final String? justificacionPrecio;

  /// Total estimado con el precio propuesto.
  Decimal get total => hectareas * precioHa;
}

/// Publicación de una solicitud. Requiere red: no hay outbox en el flavor
/// cliente.
abstract interface class SolicitudRepositorio {
  /// Lotes que el cliente tiene registrados.
  Future<List<Lote>> lotesDelCliente();

  /// Productos que el cliente suele aplicar, para elegir sin teclear.
  Future<List<String>> productosSugeridos();

  /// Cultivos habituales de la zona, para elegir sin teclear.
  Future<List<String>> cultivosSugeridos();

  /// Crea la solicitud y la abre a los pilotos. Lanza [SolicitudSinConexion]
  /// si no hay red.
  Future<Solicitud> publicar(NuevaSolicitud solicitud);
}
