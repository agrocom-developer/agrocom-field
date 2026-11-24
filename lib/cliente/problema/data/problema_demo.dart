import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/problema_repositorio.dart';

class ProblemaDemo implements ProblemaRepositorio {
  ProblemaDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 500),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  @override
  Future<ProblemaReportado?> delServicio(String servicioId) async {
    _almacen.exigirRed();
    return _almacen.problemas[servicioId];
  }

  @override
  Future<ProblemaReportado> reportar(ReporteProblema reporte) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final previo = _almacen.problemas[reporte.servicioId];
    if (previo != null) return previo;
    final caso = ProblemaReportado(
      numeroCaso: 'C-${2041 + _almacen.problemas.length}',
      servicioId: reporte.servicioId,
      motivo: reporte.motivo,
      detalle: reporte.detalle,
      abiertoEn: _almacen.datos.ahora,
    );
    _almacen.problemas[reporte.servicioId] = caso;
    final s = _almacen.porId(reporte.servicioId);
    if (s != null) {
      _almacen.reemplazar(s.copiarCon(estado: EstadoSolicitud.disputada));
    }
    return caso;
  }
}
