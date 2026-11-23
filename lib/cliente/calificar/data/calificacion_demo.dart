import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/calificacion_repositorio.dart';

class CalificacionDemo implements CalificacionRepositorio {
  CalificacionDemo(this._almacen);

  final AlmacenDemoCliente _almacen;

  @override
  Future<void> calificarProveedor({
    required String servicioId,
    required int puntaje,
    String? comentario,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final servicio = _almacen.porId(servicioId);
    if (servicio == null || servicio.puntajeDelCliente != null) return;
    _almacen.reemplazar(servicio.copiarCon(puntajeDelCliente: puntaje));
  }

  @override
  Future<ResumenCalificaciones> recibidas() async {
    final lista = _almacen.datos.calificacionesDelCliente;
    final suma = lista.fold<int>(0, (a, c) => a + c.puntaje);
    return ResumenCalificaciones(
      promedio: lista.isEmpty ? 0 : suma / lista.length,
      total: lista.length,
      recientes: lista,
    );
  }
}
