import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../cuenta/domain/cuenta_repositorio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_servicios.dart';
import '../domain/inicio_cliente_repositorio.dart';
import '../domain/reglas_inicio_cliente.dart';

/// Resumen del inicio armado con la API: los servicios del cliente, su
/// nombre y los avisos sin leer (`GET /api/notificaciones`).
class InicioClienteRed implements InicioClienteRepositorio {
  InicioClienteRed(this._fuente, this._http, this._cuenta);

  final FuenteServicios _fuente;
  final ClienteHttp _http;
  final CuentaRepositorio _cuenta;

  /// Cuántos avisos se muestran a la vez: el inicio no es un buzón.
  static const maximoAvisos = 3;

  @override
  Stream<ResumenInicio> observar() async* {
    try {
      final perfil = await _perfil();
      await for (final servicios in _fuente.observar()) {
        yield ReglasInicioCliente.resumir(
          nombre: perfil.nombre.trim().split(RegExp(r'\s+')).first,
          empresa: perfil.empresa.isEmpty ? null : perfil.empresa,
          servicios: servicios,
          avisos: await _avisos(),
        );
      }
    } on SinConexion {
      throw const InicioSinConexion();
    }
  }

  Future<CuentaCliente> _perfil() => _cuenta.cuenta();

  Future<List<AvisoInicio>> _avisos() async {
    try {
      final r = await _http.obtener('/api/notificaciones');
      final datos = r['data'];
      if (datos is! List) return const [];
      final avisos = <AvisoInicio>[];
      for (final n in datos) {
        if (n is! Map || n['leida'] == true) continue;
        final tipo = '${n['tipo']}';
        avisos.add(
          AvisoInicio(
            id: 'n${n['id']}',
            titulo: _tituloDe(tipo),
            detalle: '${n['titulo']}',
            tono: _esAlerta(tipo)
                ? TonoAvisoInicio.alerta
                : TonoAvisoInicio.info,
          ),
        );
        if (avisos.length == maximoAvisos) break;
      }
      return avisos;
    } on FallaMarketplace {
      // Los avisos son un extra: sin ellos el inicio sigue siendo útil.
      return const [];
    }
  }

  static bool _esAlerta(String tipo) =>
      tipo.contains('disputa') ||
      tipo.contains('sin_proveedor') ||
      tipo.contains('cancelada') ||
      tipo.contains('suspendida');

  static String _tituloDe(String tipo) {
    if (tipo.contains('disputa')) return 'Novedad en tu reclamo';
    if (tipo.contains('completada')) return 'Servicio completado';
    if (tipo.contains('sin_proveedor')) return 'Aún no hay proveedor';
    if (tipo.contains('cancelada')) return 'Servicio cancelado';
    if (tipo.contains('asignada')) return 'Ya tienes proveedor';
    return 'Aviso de Agrocom';
  }
}
