import 'precio_final.dart';

/// Precio final de un servicio terminado. Online-first: confirmar requiere
/// red porque es una decisión del cliente que el servidor registra.
abstract interface class PrecioFinalRepositorio {
  /// El precio que cerró el piloto, o `null` mientras no lo cierre
  /// (`{precio_final: null}`).
  Future<PrecioFinal?> ver(String solicitudId);

  /// Confirma el precio final. Idempotente: confirmar de nuevo devuelve el
  /// mismo registro. Lanza `OperacionRechazada` con motivo `estado_invalido`
  /// si el servicio aún no terminó.
  Future<PrecioFinal> confirmar(String solicitudId);
}
