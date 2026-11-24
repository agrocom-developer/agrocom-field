import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/calificacion_repositorio.dart';

class CalificacionDemo implements CalificacionRepositorio {
  CalificacionDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 400),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  @override
  Future<void> calificarProveedor({
    required String servicioId,
    required int puntaje,
    Set<EtiquetaCalificacion> etiquetas = const {},
    String? comentario,
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final servicio = _almacen.porId(servicioId);
    if (servicio == null || servicio.puntajeDelCliente != null) return;
    _almacen.calificaciones[servicioId] = CalificacionEmitida(
      servicioId: servicioId,
      puntaje: puntaje,
      etiquetas: Set.unmodifiable(etiquetas),
      comentario: comentario,
      fecha: _almacen.datos.ahora,
    );
    _almacen.reemplazar(
      servicio.copiarCon(
        puntajeDelCliente: puntaje,
        estado: EstadoSolicitud.calificada,
      ),
    );
  }

  @override
  Future<CalificacionEmitida?> emitida(String servicioId) async {
    _almacen.exigirRed();
    final guardada = _almacen.calificaciones[servicioId];
    if (guardada != null) return guardada;
    final servicio = _almacen.porId(servicioId);
    final puntaje = servicio?.puntajeDelCliente;
    if (servicio == null || puntaje == null) return null;
    return CalificacionEmitida(
      servicioId: servicioId,
      puntaje: puntaje,
      etiquetas: puntaje >= 5
          ? const {
              EtiquetaCalificacion.puntualidad,
              EtiquetaCalificacion.coberturaPareja,
            }
          : const {EtiquetaCalificacion.comunicacion},
      fecha: servicio.ventanaDesde.add(const Duration(days: 1)),
    );
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
