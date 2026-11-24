// Dobles de prueba del flavor cliente: repositorios controlables y una app
// armada con datos demo de reloj fijo, para tests de widget y goldens.

import 'dart:async';

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/cuenta/data/cuenta_demo.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/inicio/data/inicio_cliente_demo.dart';
import 'package:agrocom_field/cliente/inicio/domain/inicio_cliente_repositorio.dart';
import 'package:agrocom_field/cliente/problema/data/problema_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/cliente/solicitudes/data/solicitudes_demo.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';

/// Reloj fijo: las fechas de los datos demo no cambian entre corridas.
DateTime relojFijo() => DateTime(2026, 11, 20, 10);

AlmacenDemoCliente almacenFijo() =>
    AlmacenDemoCliente(datos: DatosDemo(reloj: relojFijo));

/// Acceso que nunca termina de leer la sesión: deja la splash en pantalla.
class AccesoPendiente implements AccesoRepositorio {
  @override
  Future<SesionCliente?> sesionActual() => Completer<SesionCliente?>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Acceso que falla al leer el estado guardado las primeras [fallos] veces.
class AccesoQueFalla implements AccesoRepositorio {
  AccesoQueFalla({this.fallos = 1});

  int fallos;

  @override
  Future<SesionCliente?> sesionActual() async {
    if (fallos > 0) {
      fallos--;
      throw StateError('almacenamiento no disponible');
    }
    return null;
  }

  @override
  Future<bool> onboardingVisto() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Inicio controlado por el test: emite lo que se le pida.
class InicioControlado implements InicioClienteRepositorio {
  InicioControlado(this._crear);

  /// Nunca emite: el inicio queda en el esqueleto.
  InicioControlado.pendiente()
    : _crear = (() => StreamController<ResumenInicio>().stream);

  InicioControlado.fijo(ResumenInicio resumen)
    : _crear = (() => Stream.value(resumen));

  final Stream<ResumenInicio> Function() _crear;
  int suscripciones = 0;

  @override
  Stream<ResumenInicio> observar() {
    suscripciones++;
    return _crear();
  }
}

/// Dependencias demo con reloj fijo y sin latencias, salvo lo que el test
/// reemplace.
DependenciasCliente dependenciasDePrueba({
  bool primerUso = false,
  AccesoRepositorio? acceso,
  InicioClienteRepositorio? inicio,
  String? notaAcceso,
}) {
  final almacen = almacenFijo();
  return DependenciasCliente(
    solicitudes: SolicitudesDemo(almacen, latencia: Duration.zero),
    solicitud: SolicitudDemo(almacen, latencia: Duration.zero),
    ofertas: OfertasDemo(almacen, latencia: Duration.zero),
    seguimiento: SeguimientoDemo(almacen, latencia: Duration.zero),
    calificacion: CalificacionDemo(almacen, latencia: Duration.zero),
    problema: ProblemaDemo(almacen, latencia: Duration.zero),
    cuenta: CuentaDemo(almacen),
    acceso:
        acceso ??
        AccesoDemo(
          almacen,
          latencia: Duration.zero,
          onboardingVisto: !primerUso,
          sesionIniciada: !primerUso,
        ),
    inicio: inicio ?? InicioClienteDemo(almacen, latencia: Duration.zero),
    notaAcceso: notaAcceso,
  );
}
