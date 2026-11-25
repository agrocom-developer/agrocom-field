import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/precio_final.dart';
import '../domain/precio_final_repositorio.dart';

/// `GET /api/solicitudes/{id}/precio-final` y `POST …/precio-final/confirmar`.
class PrecioFinalRed implements PrecioFinalRepositorio {
  PrecioFinalRed(this._http);

  final ClienteHttp _http;

  /// Lee el objeto `precio_final` del contrato; `null` si aún no existe.
  static PrecioFinal? leer(Object? j) {
    if (j is! Map) return null;
    final ha = MapeoSolicitud.decimalOpcional(j['hectareas_ejecutadas']);
    final precio = MapeoSolicitud.decimalOpcional(j['precio_ha_acordado']);
    final monto = MapeoSolicitud.decimalOpcional(j['monto_final']);
    if (ha == null || precio == null || monto == null) return null;
    return PrecioFinal(
      hectareasEjecutadas: ha,
      precioHaAcordado: precio,
      montoFinal: monto,
      confirmado: j['confirmado'] == true,
      confirmadoEn: MapeoSolicitud.fecha(j['confirmado_en']),
    );
  }

  @override
  Future<PrecioFinal?> ver(String solicitudId) async => leer(
    (await _http.obtener(
      '/api/solicitudes/$solicitudId/precio-final',
    ))['precio_final'],
  );

  @override
  Future<PrecioFinal> confirmar(String solicitudId) async {
    final r = await _http.enviar(
      '/api/solicitudes/$solicitudId/precio-final/confirmar',
    );
    final p = leer(r['precio_final']);
    if (p == null) {
      throw const OperacionRechazada('No pudimos confirmar el precio final.');
    }
    return p;
  }
}
