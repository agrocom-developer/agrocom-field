import 'package:decimal/decimal.dart';

import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../domain/solicitud.dart';
import '../domain/solicitudes_repositorio.dart';

/// Solicitudes del cliente contra la API (`/api/solicitudes`).
class SolicitudesRed implements SolicitudesRepositorio {
  SolicitudesRed(this._http, this._fuente);

  final ClienteHttp _http;
  final FuenteSolicitudes _fuente;

  @override
  Stream<List<Solicitud>> observar() => _fuente.observar();

  @override
  Future<Solicitud?> porId(String id) => _fuente.detalle(id);

  @override
  Future<void> refrescar() => _fuente.invalidar();

  @override
  Future<void> cambiarPrecio(String id, Decimal precioHa) async {
    await _http.enviar(
      '/api/solicitudes/$id/precio',
      datos: {'precio_ha_propuesto': '$precioHa'},
    );
    await _fuente.invalidar();
  }

  @override
  Future<void> cancelar(String id, String motivo) async {
    await _http.enviar(
      '/api/solicitudes/$id/cancelar',
      datos: {'motivo': motivo.trim()},
    );
    await _fuente.invalidar();
  }

  @override
  Future<void> renovar(String id) async {
    await _http.enviar('/api/solicitudes/$id/renovar');
    await _fuente.invalidar();
  }
}
