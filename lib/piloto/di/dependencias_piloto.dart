import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/sesion_vuelo/presentation/fabricas_sesion_vuelo.dart';
import '../demo/almacen_demo_piloto.dart';
import '../demo/sesion_vuelo_demo.dart';
import '../dron/data/drones_demo.dart';
import '../dron/domain/drones_repositorio.dart';
import '../ofertas/data/ofertas_demo.dart';
import '../ofertas/domain/ofertas_repositorio.dart';
import '../perfil/data/perfil_demo.dart';
import '../perfil/domain/perfil_repositorio.dart';
import '../servicio_asignado/data/servicio_asignado_demo.dart';
import '../servicio_asignado/domain/servicio_asignado_repositorio.dart';

/// Repositorios del flavor piloto para la superficie del marketplace
/// (ofertas, servicio asignado con su sesión de vuelo, drones, perfil). Hoy solo existe la
/// implementación demo (`MODO_DEMO`, ADR 0010); las reales llegan con las
/// tareas 34 a 37 de la cola y se eligen aquí.
class DependenciasPiloto {
  const DependenciasPiloto({
    required this.ofertas,
    required this.servicioAsignado,
    required this.drones,
    required this.perfil,
    required this.sesionVuelo,
  });

  /// [almacen] permite fijar los datos (y su reloj) desde una prueba.
  factory DependenciasPiloto.demo({AlmacenDemoPiloto? almacen}) {
    almacen ??= AlmacenDemoPiloto();
    return DependenciasPiloto(
      ofertas: OfertasDemo(almacen),
      servicioAsignado: ServicioAsignadoDemo(almacen),
      drones: DronesDemo(almacen),
      perfil: PerfilDemo(almacen),
      sesionVuelo: fabricasSesionVueloDemo(almacen),
    );
  }

  final OfertasRepositorio ofertas;
  final ServicioAsignadoRepositorio servicioAsignado;
  final DronesRepositorio drones;
  final PerfilRepositorio perfil;

  /// Lo que arma la pantalla de sesión de vuelo de un servicio asignado.
  final FabricasSesionVuelo sesionVuelo;

  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<OfertasRepositorio>.value(value: ofertas),
      RepositoryProvider<ServicioAsignadoRepositorio>.value(
        value: servicioAsignado,
      ),
      RepositoryProvider<DronesRepositorio>.value(value: drones),
      RepositoryProvider<PerfilRepositorio>.value(value: perfil),
      RepositoryProvider<FabricasSesionVuelo>.value(value: sesionVuelo),
    ],
    child: child,
  );
}
