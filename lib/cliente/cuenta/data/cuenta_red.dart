import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../domain/cuenta_repositorio.dart';

/// Datos de la cuenta del cliente: el usuario (`GET /api/auth/sesion`) y su
/// ficha (`GET /api/clientes/mi`).
class CuentaRed implements CuentaRepositorio {
  CuentaRed(this._http);

  final ClienteHttp _http;

  @override
  Future<CuentaCliente> cuenta() async {
    final sesion = await _http.obtener('/api/auth/sesion');
    final ficha = await _http.obtener('/api/clientes/mi');
    final solicitudes = await _http.obtener(
      '/api/solicitudes',
      query: {'page': 1},
    );
    final usuario = sesion['usuario'];
    final cliente = ficha['cliente'];
    if (usuario is! Map || cliente is! Map) {
      throw const OperacionRechazada('No pudimos leer los datos de tu cuenta.');
    }
    return CuentaCliente(
      nombre: '${usuario['name']}',
      empresa: cliente['tipo'] == 'empresa' ? '${cliente['razon_social']}' : '',
      telefono: '${cliente['telefono'] ?? ''}',
      usuario: '${usuario['username']}',
      serviciosTotales: (solicitudes['total'] as int?) ?? 0,
    );
  }
}
