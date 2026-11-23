import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../demo/datos_demo.dart';
import '../../dominio/dominio.dart';

/// Estado en memoria del proveedor en modo demo. Lo comparten los flavors
/// `piloto` y `auxiliar`: la bandeja, el perfil y los drones son del
/// proveedor, no de un rol.
class AlmacenDemoProveedor {
  AlmacenDemoProveedor({DatosDemo? datos}) : datos = datos ?? DatosDemo() {
    _ofertas = this.datos.ofertasIniciales();
    _asignados = [this.datos.servicios.first];
  }

  final DatosDemo datos;
  late List<Oferta> _ofertas;
  late List<Servicio> _asignados;
  final _ofertasCambios = StreamController<List<Oferta>>.broadcast();
  final _asignadosCambios = StreamController<List<Servicio>>.broadcast();
  final _redCambios = StreamController<bool>.broadcast();
  final _respuestas = <String, ResultadoRespuestaOferta>{};
  bool _enLinea = true;

  Proveedor get piloto => datos.pilotoDemo;

  List<Oferta> get ofertas => List.unmodifiable(_ofertas);
  List<Servicio> get asignados => List.unmodifiable(_asignados);

  /// Hay red en el dispositivo. La demo arranca en línea.
  bool get enLinea => _enLinea;

  set enLinea(bool valor) {
    if (valor == _enLinea) return;
    _enLinea = valor;
    _redCambios.add(valor);
  }

  Stream<bool> observarRed() async* {
    yield _enLinea;
    yield* _redCambios.stream;
  }

  Stream<List<Oferta>> observarOfertas() async* {
    yield ofertas;
    yield* _ofertasCambios.stream;
  }

  Stream<List<Servicio>> observarAsignados() async* {
    yield asignados;
    yield* _asignadosCambios.stream;
  }

  Oferta? oferta(String id) {
    for (final o in _ofertas) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Registra la respuesta una sola vez por clave (idempotencia) y quita la
  /// oferta de la bandeja. Una oferta aceptada pasa a servicios asignados.
  ResultadoRespuestaOferta responder(
    String clave,
    String ofertaId,
    ResultadoRespuestaOferta Function(Oferta) decidir,
  ) {
    final previa = _respuestas[clave];
    if (previa != null) return previa;
    final o = oferta(ofertaId);
    if (o == null) return ResultadoRespuestaOferta.expirada;
    final resultado = decidir(o);
    _respuestas[clave] = resultado;
    _ofertas = _ofertas.where((x) => x.id != ofertaId).toList();
    _ofertasCambios.add(ofertas);
    if (resultado == ResultadoRespuestaOferta.aceptada) {
      _asignados = [
        ..._asignados,
        Servicio(
          id: 'srv-${o.id}',
          lote: o.lote,
          producto: o.producto,
          dosisLitrosPorHectarea: Decimal.parse('1.2'),
          hectareasDeclaradas: o.lote.hectareas,
          hectareasCubiertas: Decimal.zero,
          fechaDeseada: o.fechaServicio,
          estado: EstadoServicio.asignado,
          precio: o.pago,
          solicitadoEn: o.recibidaEn,
          proveedor: piloto,
          clienteNombre: DatosDemo.clienteNombre,
        ),
      ];
      _asignadosCambios.add(asignados);
    }
    return resultado;
  }
}
