import '../../../dominio/dominio.dart';
import '../../demo/almacen_demo_proveedor.dart';
import '../domain/ofertas_repositorio.dart';

/// Oferta que siempre se pierde en la demo («otro proveedor aceptó antes»),
/// para ver ese estado sin esperar a que ocurra.
const ofertaPerdidaEnDemo = 'of-2';

class OfertasDemo implements OfertasRepositorio {
  OfertasDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 600),
  });

  final AlmacenDemoProveedor _almacen;
  final Duration latencia;

  @override
  Stream<List<Oferta>> observar() => _almacen.observarOfertas();

  @override
  Future<ResultadoRespuestaOferta> aceptar(
    String ofertaId, {
    required String claveIdempotencia,
  }) async {
    await Future<void>.delayed(latencia);
    if (!_almacen.enLinea) return ResultadoRespuestaOferta.sinConexion;
    return _almacen.responder(claveIdempotencia, ofertaId, (o) {
      if (o.id == ofertaPerdidaEnDemo) return ResultadoRespuestaOferta.perdida;
      if (o.restante(_almacen.datos.ahora) == Duration.zero) {
        return ResultadoRespuestaOferta.expirada;
      }
      return ResultadoRespuestaOferta.aceptada;
    });
  }

  @override
  Future<ResultadoRespuestaOferta> rechazar(
    String ofertaId, {
    required String claveIdempotencia,
  }) async {
    await Future<void>.delayed(latencia);
    if (!_almacen.enLinea) return ResultadoRespuestaOferta.sinConexion;
    return _almacen.responder(
      claveIdempotencia,
      ofertaId,
      (_) => ResultadoRespuestaOferta.rechazada,
    );
  }
}
