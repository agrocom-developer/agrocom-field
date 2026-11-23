import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/demo/recorrido_demo.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/seguimiento_repositorio.dart';

/// Simula el avance del dron: emite un fotograma cada [intervalo] sumando
/// [pasoHectareas] hasta completar el lote.
class SeguimientoDemo implements SeguimientoRepositorio {
  SeguimientoDemo(
    this._almacen, {
    this.intervalo = const Duration(seconds: 2),
    String pasoHectareas = '1.5',
  }) : _paso = Decimal.parse(pasoHectareas);

  final AlmacenDemoCliente _almacen;
  final Duration intervalo;
  final Decimal _paso;

  @override
  Stream<SeguimientoVivo> observar(String servicioId) async* {
    final servicio = _almacen.porId(servicioId);
    if (servicio == null) return;
    final recorrido = RecorridoDemo.paraLote(servicio.lote);
    var cubiertas = servicio.hectareasCubiertas;
    yield recorrido.fotograma(servicio, cubiertas);
    if (servicio.estado != EstadoServicio.enEjecucion) return;
    while (cubiertas < servicio.hectareasDeclaradas) {
      await Future<void>.delayed(intervalo);
      cubiertas = cubiertas + _paso;
      if (cubiertas > servicio.hectareasDeclaradas) {
        cubiertas = servicio.hectareasDeclaradas;
      }
      yield recorrido.fotograma(servicio, cubiertas);
    }
  }
}
