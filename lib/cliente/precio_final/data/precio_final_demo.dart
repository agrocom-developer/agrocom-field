import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/precio_final.dart';
import '../domain/precio_final_repositorio.dart';

/// Precio final en memoria: sale de la solicitud finalizada del almacén demo
/// y se confirma una sola vez, como el servidor.
class PrecioFinalDemo implements PrecioFinalRepositorio {
  PrecioFinalDemo(this._almacen, {this.latencia = Duration.zero});

  final AlmacenDemoCliente _almacen;
  final Duration latencia;
  final _confirmados = <String, DateTime>{};

  PrecioFinal? _de(String id) {
    final s = _almacen.porId(id);
    if (s == null) return null;
    if (s.estado != EstadoSolicitud.finalizada &&
        s.estado != EstadoSolicitud.calificada) {
      return null;
    }
    return PrecioFinal(
      hectareasEjecutadas: s.hectareasEjecutadas ?? s.hectareas,
      precioHaAcordado: s.precioHaVigente,
      montoFinal: s.totalAPagar,
      confirmado: _confirmados.containsKey(id),
      confirmadoEn: _confirmados[id],
    );
  }

  @override
  Future<PrecioFinal?> ver(String solicitudId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    return _de(solicitudId);
  }

  @override
  Future<PrecioFinal> confirmar(String solicitudId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final p = _de(solicitudId);
    if (p == null) {
      throw const OperacionRechazada(
        'El servicio todavía no terminó.',
        codigo: 409,
        motivo: 'estado_invalido',
      );
    }
    _confirmados.putIfAbsent(solicitudId, () => _almacen.ahora);
    return _de(solicitudId)!;
  }
}
