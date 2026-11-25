import 'dart:typed_data';

import 'seguimiento.dart';

/// Seguimiento de un servicio adjudicado: avance con fotos, última ubicación
/// del piloto y chat. Online-first (ADR 0017): el cliente consulta con
/// sondeo corto y escribe en línea; sin red lanza `SinConexion`.
abstract interface class SeguimientoRepositorio {
  Future<AvanceServicio> avance(String solicitudId);

  /// La última ubicación, o `null` si el piloto no la reportó o el servicio
  /// no está en ejecución.
  Future<UbicacionPiloto?> ubicacionDelPiloto(String solicitudId);

  /// Mensajes posteriores a [despues] (todos si es `null`), en orden.
  Future<PaginaMensajes> mensajes(String solicitudId, {String? despues});

  /// Envía un mensaje. [claveCliente] nace al escribirlo y se reutiliza en
  /// cada reintento: el servidor devuelve el mismo mensaje.
  Future<MensajeChat> enviarMensaje(
    String solicitudId, {
    required String texto,
    required String claveCliente,
  });

  /// Envía una foto por el chat. [bytes] ya vienen comprimidos a menos de
  /// 300 KB (invariante 7); [pie] es opcional (hasta 280 caracteres).
  /// [claveCliente] hace idempotente el reintento, como en el texto.
  Future<MensajeChat> enviarFoto(
    String solicitudId, {
    required Uint8List bytes,
    required String claveCliente,
    String? pie,
  });

  /// Descarga una foto (de avance o del dron) con la sesión del cliente.
  Future<Uint8List> archivo(String ruta);

  Future<void> marcarLeidos(String solicitudId, String cursor);
}
