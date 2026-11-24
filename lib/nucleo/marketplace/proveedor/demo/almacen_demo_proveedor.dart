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

  void _reemplazar(String id, Servicio Function(Servicio) cambio) {
    if (!_asignados.any((s) => s.id == id)) return;
    _asignados = [for (final s in _asignados) s.id == id ? cambio(s) : s];
    _asignadosCambios.add(asignados);
  }

  /// El servicio pasa a ejecución al abrirse su primera sesión de vuelo.
  void iniciarServicio(String id) => _reemplazar(
    id,
    (s) => s.estado == EstadoServicio.asignado
        ? s.copiarCon(estado: EstadoServicio.enEjecucion)
        : s,
  );

  /// Suma las hectáreas de una sesión cerrada, sin pasar de las declaradas.
  void registrarAvance(String id, Decimal hectareas) => _reemplazar(id, (s) {
    final total = s.hectareasCubiertas + hectareas;
    return s.copiarCon(
      hectareasCubiertas: total > s.hectareasDeclaradas
          ? s.hectareasDeclaradas
          : total,
    );
  });

  /// El cierre del trabajo completa el servicio.
  void completarServicio(String id) =>
      _reemplazar(id, (s) => s.copiarCon(estado: EstadoServicio.completado));

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
