import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/fuente_servicios.dart';
import '../domain/servicios_cliente_repositorio.dart';

/// Servicios del cliente leídos de la API (`GET /api/solicitudes`). Sin red
/// muestra lo último conocido; si no hay nada guardado, emite `SinConexion`.
class ServiciosClienteRed implements ServiciosClienteRepositorio {
  ServiciosClienteRed(this._fuente);

  final FuenteServicios _fuente;

  @override
  Stream<List<Servicio>> observar() => _fuente.observar();

  @override
  Future<Servicio?> porId(String id) => _fuente.detalle(id);
}
