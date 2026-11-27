import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../demo/almacen_demo_cliente.dart';
import '../../../nucleo/marketplace/precio/justificacion_precio.dart';
import '../domain/comparador_ofertas.dart';
import '../domain/oferta_recibida.dart';
import '../domain/ofertas_repositorio.dart';

/// Negociación simulada en memoria: aceptar adjudica la solicitud y cierra
/// las demás ofertas; contraofertar abre la siguiente ronda y, en modo
/// automático, el piloto responde con el punto medio.
class OfertasDemo implements OfertasRepositorio {
  OfertasDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 500),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  OfertaRecibida _vigente(String id) {
    final o = _almacen.ofertaPorId(id);
    if (o == null ||
        o.estado != EstadoOferta.vigente ||
        !o.vigenteA(_almacen.ahora)) {
      throw const OfertaCambio(
        'La oferta ya no está vigente: venció, la retiraron o ya se '
        'respondió.',
      );
    }
    return o;
  }

  @override
  Future<List<OfertaRecibida>> deLaSolicitud(
    String solicitudId, {
    FiltrosOfertas filtros = const FiltrosOfertas(),
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    return ComparadorOfertas.aplicar(_almacen.ofertasDe(solicitudId), filtros);
  }

  @override
  Future<void> aceptar(String ofertaId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final oferta = _vigente(ofertaId);
    final s = _almacen.porId(oferta.solicitudId);
    if (s != null && !s.estado.negociando) {
      throw const OfertaCambio('La solicitud ya se adjudicó a otro piloto.');
    }
    _almacen.adjudicar(oferta);
  }

  @override
  Future<void> contraofertar(
    String ofertaId, {
    required Decimal precioHa,
    required String claveIdempotencia,
    String? nota,
    String? justificacionPrecio,
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final oferta = _vigente(ofertaId);
    if (oferta.esDefinitiva) {
      throw const OfertaCambio(
        'Esta es la última ronda: solo puedes aceptar o rechazar.',
      );
    }
    final nueva = _almacen.contraofertar(
      oferta,
      AutorOferta.cliente,
      precioHa,
      nota: nota,
      justificacionPrecio: JustificacionPrecio.normalizar(justificacionPrecio),
    );
    _almacen.responderContraoferta(nueva, oferta.precioHa);
  }

  @override
  Future<void> rechazar(String ofertaId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    _almacen.rechazarOferta(_vigente(ofertaId));
  }
}
