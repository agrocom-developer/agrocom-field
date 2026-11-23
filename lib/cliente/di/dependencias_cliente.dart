import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../acceso/data/acceso_demo.dart';
import '../acceso/domain/acceso_repositorio.dart';
import '../calificar/data/calificacion_demo.dart';
import '../calificar/domain/calificacion_repositorio.dart';
import '../cuenta/data/cuenta_demo.dart';
import '../cuenta/domain/cuenta_repositorio.dart';
import '../demo/almacen_demo_cliente.dart';
import '../inicio/data/inicio_cliente_demo.dart';
import '../inicio/domain/inicio_cliente_repositorio.dart';
import '../seguimiento/data/seguimiento_demo.dart';
import '../seguimiento/domain/seguimiento_repositorio.dart';
import '../servicios/data/servicios_cliente_demo.dart';
import '../servicios/domain/servicios_cliente_repositorio.dart';
import '../solicitar/data/solicitud_demo.dart';
import '../solicitar/domain/solicitud_repositorio.dart';

/// Repositorios del flavor cliente. La interfaz de cada feature es lo único
/// que ven las pantallas; este contenedor decide qué implementación se usa.
///
/// El flavor cliente es online-first: no usa `drift`, `SyncEngine` ni outbox,
/// y por eso este archivo no importa `nucleo/db` ni `nucleo/sync` (ADR 0009,
/// regla 5; lo vigila `test/arquitectura/importaciones_test.dart`).
class DependenciasCliente {
  const DependenciasCliente({
    required this.servicios,
    required this.solicitud,
    required this.seguimiento,
    required this.calificacion,
    required this.cuenta,
    required this.acceso,
    required this.inicio,
    this.notaAcceso,
  });

  /// Repositorios en memoria con datos ficticios (`MODO_DEMO`, ADR 0010).
  ///
  /// Por defecto la sesión ya está iniciada y la app abre en el inicio. Con
  /// [primerUso] arranca como recién instalada: presentación, acceso y
  /// después el inicio (así corre `main_cliente.dart` en modo demo).
  factory DependenciasCliente.demo({bool primerUso = false}) {
    final almacen = AlmacenDemoCliente();
    return DependenciasCliente(
      servicios: ServiciosClienteDemo(almacen),
      solicitud: SolicitudDemo(almacen),
      seguimiento: SeguimientoDemo(almacen),
      calificacion: CalificacionDemo(almacen),
      cuenta: CuentaDemo(almacen),
      acceso: AccesoDemo(
        almacen,
        onboardingVisto: !primerUso,
        sesionIniciada: !primerUso,
      ),
      inicio: InicioClienteDemo(almacen),
      notaAcceso:
          'Modo demo: entra con cualquier correo y una contraseña de 8 '
          'caracteres o más. Los datos son ficticios.',
    );
  }

  final ServiciosClienteRepositorio servicios;
  final SolicitudRepositorio solicitud;
  final SeguimientoRepositorio seguimiento;
  final CalificacionRepositorio calificacion;
  final CuentaRepositorio cuenta;
  final AccesoRepositorio acceso;
  final InicioClienteRepositorio inicio;

  /// Nota que la pantalla de ingreso muestra bajo el formulario; solo la
  /// define el modo demo.
  final String? notaAcceso;

  /// Expone los repositorios al árbol de widgets.
  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ServiciosClienteRepositorio>.value(value: servicios),
      RepositoryProvider<SolicitudRepositorio>.value(value: solicitud),
      RepositoryProvider<SeguimientoRepositorio>.value(value: seguimiento),
      RepositoryProvider<CalificacionRepositorio>.value(value: calificacion),
      RepositoryProvider<CuentaRepositorio>.value(value: cuenta),
      RepositoryProvider<AccesoRepositorio>.value(value: acceso),
      RepositoryProvider<InicioClienteRepositorio>.value(value: inicio),
    ],
    child: child,
  );
}
