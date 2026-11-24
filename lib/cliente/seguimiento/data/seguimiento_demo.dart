import 'dart:async';

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
  Stream<SeguimientoVivo> observar(String servicioId) {
    Timer? reloj;
    late final StreamController<SeguimientoVivo> control;

    void arrancar() {
      if (_almacen.sinRed) {
        control
          ..addError(const SinConexion())
          ..close();
        return;
      }
      final servicio = _almacen.porId(servicioId);
      if (servicio == null) {
        control.close();
        return;
      }
      final recorrido = RecorridoDemo.paraLote(servicio.lote);
      final inicial = servicio.hectareasCubiertas;
      var cubiertas = inicial;
      control.add(recorrido.fotograma(servicio, cubiertas));
      if (servicio.estado != EstadoServicio.enEjecucion) {
        control.close();
        return;
      }

      void avanzar() {
        if (cubiertas >= servicio.hectareasDeclaradas) {
          control.close();
          return;
        }
        reloj = Timer(intervalo, () {
          if (_almacen.sinRed) {
            control
              ..addError(const SinConexion())
              ..close();
            return;
          }
          cubiertas = cubiertas + _paso;
          if (cubiertas > servicio.hectareasDeclaradas) {
            cubiertas = servicio.hectareasDeclaradas;
          }
          control.add(
            _conEta(
              recorrido.fotograma(servicio, cubiertas),
              servicio,
              inicial,
            ),
          );
          avanzar();
        });
      }

      avanzar();
    }

    // Al cancelar la suscripción se corta el reloj: no queda nada vivo
    // cuando el cliente sale de la pantalla.
    control = StreamController<SeguimientoVivo>(
      onListen: arrancar,
      onCancel: () => reloj?.cancel(),
    );
    return control.stream;
  }

  /// El tiempo restante baja en proporción a lo que falta cubrir.
  SeguimientoVivo _conEta(
    SeguimientoVivo f,
    Servicio servicio,
    Decimal inicial,
  ) {
    final etaInicial = servicio.etaMinutos;
    final tramo = servicio.hectareasDeclaradas - inicial;
    if (etaInicial == null || tramo <= Decimal.zero) return f;
    final falta = servicio.hectareasDeclaradas - f.hectareasCubiertas;
    final eta = (Decimal.fromInt(etaInicial) * falta / tramo)
        .toDecimal(scaleOnInfinitePrecision: 2)
        .ceil()
        .toBigInt()
        .toInt();
    return SeguimientoVivo(
      estado: f.estado,
      posicionDron: f.posicionDron,
      hectareasCubiertas: f.hectareasCubiertas,
      hectareasDeclaradas: f.hectareasDeclaradas,
      trazado: f.trazado,
      etaMinutos: eta,
    );
  }
}
