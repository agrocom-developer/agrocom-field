import 'dart:math';

import 'package:decimal/decimal.dart';

import '../../api/marketplace_http.dart';
import '../dominio/falla.dart';
import 'pago_confirmado.dart';

/// Códigos de negocio de `POST /api/solicitudes/{id}/pago-confirmado`.
abstract final class MotivoPago {
  /// `409`: otro `uuid_cliente` ya confirmó el pago de esta solicitud.
  static const yaConfirmado = 'pago_ya_confirmado';

  /// `403`: la cuenta no es el titular del proveedor adjudicado.
  static const soloTitular = 'pago_solo_titular';
}

/// Confirmación del pago hecho fuera de la aplicación (ADR 0020).
///
/// Lo escribe solo el proveedor titular; el cliente y el proveedor lo leen.
abstract interface class PagosRepositorio {
  /// El pago ya confirmado de la solicitud, o `null` si aún no.
  Future<PagoConfirmado?> ver(int solicitudId);

  /// Informa que el proveedor recibió el pago. Es idempotente por
  /// [uuidCliente]: repetirlo con el mismo valor devuelve el mismo registro.
  /// Con otro valor sobre un pago ya confirmado falla con
  /// [OperacionRechazada] y motivo [MotivoPago.yaConfirmado].
  Future<PagoConfirmado> confirmar(
    int solicitudId, {
    required String uuidCliente,
    MetodoPago? metodo,
    String? nota,
  });
}

class PagosRed implements PagosRepositorio {
  PagosRed(this._http);

  final MarketplaceHttp _http;

  static String _ruta(int id) => '/api/solicitudes/$id/pago-confirmado';

  @override
  Future<PagoConfirmado?> ver(int solicitudId) async {
    final r = await _http.obtener(_ruta(solicitudId));
    final pago = r['pago'];
    if (pago is! Map) return null;
    return PagoConfirmado.desdeJson(Map<String, dynamic>.from(pago));
  }

  @override
  Future<PagoConfirmado> confirmar(
    int solicitudId, {
    required String uuidCliente,
    MetodoPago? metodo,
    String? nota,
  }) async {
    final r = await _http.enviar(
      _ruta(solicitudId),
      datos: {
        'uuid_cliente': uuidCliente,
        'metodo': ?metodo?.api,
        'nota': ?nota,
      },
    );
    final pago = r['pago'];
    if (pago is! Map) {
      throw const OperacionRechazada('No pudimos confirmar el pago.');
    }
    return PagoConfirmado.desdeJson(Map<String, dynamic>.from(pago));
  }
}

/// En memoria, para el modo demo y las pruebas. Reproduce las reglas del
/// servidor que importan a la pantalla: un solo pago por solicitud,
/// idempotente por `uuid_cliente`.
class PagosDemo implements PagosRepositorio {
  PagosDemo({Map<int, Decimal> montos = const {}, DateTime Function()? reloj})
    : _montos = montos,
      _reloj = reloj ?? DateTime.now,
      _ids = Random(1);

  final Map<int, Decimal> _montos;
  final DateTime Function() _reloj;
  final Random _ids;
  final _pagos = <int, PagoConfirmado>{};

  @override
  Future<PagoConfirmado?> ver(int solicitudId) async => _pagos[solicitudId];

  @override
  Future<PagoConfirmado> confirmar(
    int solicitudId, {
    required String uuidCliente,
    MetodoPago? metodo,
    String? nota,
  }) async {
    final previo = _pagos[solicitudId];
    if (previo != null) {
      if (previo.uuidCliente == uuidCliente) return previo;
      throw const OperacionRechazada(
        'El pago de este servicio ya estaba confirmado.',
        codigo: 409,
        motivo: MotivoPago.yaConfirmado,
      );
    }
    return _pagos[solicitudId] = PagoConfirmado(
      id: 1 + _ids.nextInt(100000),
      uuidCliente: uuidCliente,
      solicitudId: solicitudId,
      monto: _montos[solicitudId] ?? Decimal.zero,
      metodo: metodo,
      nota: nota,
      confirmadoEn: _reloj(),
    );
  }
}
