import 'dart:async';

import 'package:flutter/services.dart';

import '../../demo/almacen_demo_cliente.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';

/// Seguimiento simulado: el avance, la ubicación y el chat salen del almacén
/// en memoria. La ubicación se reporta como «hace 90 s» para que la demo
/// muestre un punto vigente.
class SeguimientoDemo implements SeguimientoRepositorio {
  SeguimientoDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 250),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  @override
  Future<AvanceServicio> avance(String solicitudId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    return _almacen.avanceDe(solicitudId);
  }

  @override
  Future<UbicacionPiloto?> ubicacionDelPiloto(String solicitudId) async {
    _almacen.exigirRed();
    final punto = _almacen.ubicacionDe(solicitudId);
    final s = _almacen.porId(solicitudId);
    if (punto == null || s?.estado != EstadoSolicitud.enEjecucion) return null;
    return UbicacionPiloto(
      punto: punto,
      capturadaEn: _almacen.ahora.subtract(const Duration(seconds: 90)),
      vigente: true,
      precisionMetros: 12,
    );
  }

  @override
  Future<PaginaMensajes> mensajes(String solicitudId, {String? despues}) async {
    _almacen.exigirRed();
    final todos = _almacen.mensajesDe(solicitudId);
    final desde = despues == null
        ? 0
        : todos.indexWhere((m) => m.id == despues) + 1;
    final nuevos = todos.sublist(desde < 0 ? 0 : desde);
    final s = _almacen.porId(solicitudId);
    return PaginaMensajes(
      mensajes: nuevos,
      cursor: todos.isEmpty ? despues : todos.last.id,
      soloLectura: s == null || s.estado == EstadoSolicitud.calificada,
    );
  }

  @override
  Future<MensajeChat> enviarMensaje(
    String solicitudId, {
    required String texto,
    required String claveCliente,
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final previo = _almacen
        .mensajesDe(solicitudId)
        .where((m) => m.claveCliente == claveCliente)
        .firstOrNull;
    if (previo != null) return previo;
    final mensaje = MensajeChat(
      id: 'm-${_almacen.nuevoId()}',
      texto: texto.trim(),
      creadoEn: _almacen.ahora,
      propio: true,
      claveCliente: claveCliente,
    );
    _almacen.agregarMensaje(solicitudId, mensaje);
    _almacen.responderMensaje(solicitudId);
    return mensaje;
  }

  @override
  Future<MensajeChat> enviarFoto(
    String solicitudId, {
    required Uint8List bytes,
    required String claveCliente,
    String? pie,
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final previo = _almacen
        .mensajesDe(solicitudId)
        .where((m) => m.claveCliente == claveCliente)
        .firstOrNull;
    if (previo != null) return previo;
    final mensaje = MensajeChat(
      id: 'm-${_almacen.nuevoId()}',
      texto: pie?.trim() ?? '',
      creadoEn: _almacen.ahora,
      propio: true,
      claveCliente: claveCliente,
      tipo: TipoMensajeChat.foto,
      // En la demo no hay servidor que guarde los bytes: se muestra una foto
      // empaquetada.
      ruta: 'assets/imagenes/fondo_dron_pulverizando.jpg',
    );
    _almacen.agregarMensaje(solicitudId, mensaje);
    return mensaje;
  }

  @override
  Future<Uint8List> archivo(String ruta) async {
    final datos = await rootBundle.load(ruta);
    return datos.buffer.asUint8List();
  }

  @override
  Future<void> marcarLeidos(String solicitudId, String cursor) async {}
}
