import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../demo/almacen_demo_cliente.dart';
import '../domain/solicitud.dart';
import '../domain/solicitudes_repositorio.dart';

class SolicitudesDemo implements SolicitudesRepositorio {
  SolicitudesDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 300),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  @override
  Stream<List<Solicitud>> observar() async* {
    _almacen.exigirRed();
    yield* _almacen.observar();
  }

  @override
  Future<Solicitud?> porId(String id) async {
    _almacen.exigirRed();
    return _almacen.porId(id);
  }

  @override
  Future<void> refrescar() async {
    _almacen.exigirRed();
    _almacen.reemplazarTodas();
  }

  @override
  Future<void> cambiarPrecio(String id, Decimal precioHa) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final s = _almacen.porId(id);
    if (s == null || !s.estado.negociando) return;
    _almacen.reemplazar(s.copiarCon(precioHaPropuesto: precioHa));
  }

  @override
  Future<void> cancelar(String id, String motivo) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final s = _almacen.porId(id);
    if (s == null) return;
    _almacen.reemplazar(s.copiarCon(estado: EstadoSolicitud.cancelada));
  }

  @override
  Future<void> renovar(String id) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final s = _almacen.porId(id);
    if (s == null || s.estado != EstadoSolicitud.expirada) return;
    _almacen.reemplazar(s.copiarCon(estado: EstadoSolicitud.abierta));
  }
}
