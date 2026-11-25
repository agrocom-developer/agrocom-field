import 'dart:async';

import '../domain/conectividad_servicio.dart';

/// Conectividad controlable para el modo demo y las pruebas: arranca con red
/// y [fijar] cambia el estado.
class ConectividadFalsa implements ConectividadServicio {
  ConectividadFalsa({EstadoRed inicial = EstadoRed.conRed}) : _actual = inicial;

  EstadoRed _actual;
  final _controlador = StreamController<EstadoRed>.broadcast();

  void fijar(EstadoRed estado) {
    if (estado == _actual) return;
    _actual = estado;
    _controlador.add(estado);
  }

  @override
  Future<EstadoRed> consultar() async => _actual;

  @override
  Stream<EstadoRed> get cambios => _controlador.stream;

  Future<void> cerrar() => _controlador.close();
}
