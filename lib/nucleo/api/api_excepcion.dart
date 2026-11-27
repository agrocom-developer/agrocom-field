import 'package:dio/dio.dart';

sealed class ApiExcepcion implements Exception {
  const ApiExcepcion();
}

/// Sin conectividad o timeout — el caso normal en el lote, no un error.
/// El repositorio que llama ApiClient la captura y deja el registro
/// `pendiente` en el outbox; nunca sube como error visible de UI.
final class ApiExcepcionRed extends ApiExcepcion {
  const ApiExcepcionRed();
}

final class ApiExcepcionServidor extends ApiExcepcion {
  const ApiExcepcionServidor(this.codigo, this.cuerpo, {this.reintentarEn});

  final int codigo;
  final Object? cuerpo;

  /// Espera que pidió el servidor con `Retry-After` (en segundos), si vino.
  /// Lo usan los `429` de las pantallas de código y de ingreso.
  final Duration? reintentarEn;
}

final class ApiExcepcionDesconocida extends ApiExcepcion {
  const ApiExcepcionDesconocida(this.original);

  final Object original;
}

ApiExcepcion mapearExcepcionDio(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const ApiExcepcionRed();
  }
  final codigo = e.response?.statusCode;
  if (codigo != null) {
    return ApiExcepcionServidor(
      codigo,
      e.response?.data,
      reintentarEn: _esperaDe(e.response?.headers.value('retry-after')),
    );
  }
  return ApiExcepcionDesconocida(e);
}

/// `Retry-After` en segundos; una fecha HTTP o un valor ilegible se ignoran
/// (la pantalla usa una espera por defecto).
Duration? _esperaDe(String? valor) {
  final segundos = int.tryParse(valor?.trim() ?? '');
  if (segundos == null || segundos <= 0) return null;
  return Duration(seconds: segundos);
}
