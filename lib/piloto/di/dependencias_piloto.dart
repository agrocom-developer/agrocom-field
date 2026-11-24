import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/sesion_vuelo/presentation/fabricas_sesion_vuelo.dart';
import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import '../demo/sesion_vuelo_demo.dart';
import '../servicio_asignado/data/servicio_asignado_demo.dart';
import '../servicio_asignado/domain/servicio_asignado_repositorio.dart';

/// Repositorios del flavor piloto para la superficie del marketplace: los
/// del proveedor (ofertas, drones, perfil; compartidos con `auxiliar`) y el
/// servicio asignado con su sesión de vuelo. La implementación demo
/// (`MODO_DEMO`, ADR 0010) y la real se eligen aquí.
class DependenciasPiloto {
  const DependenciasPiloto({
    required this.proveedor,
    required this.servicioAsignado,
    required this.sesionVuelo,
  });

  /// [almacen] permite fijar los datos (y su reloj) desde una prueba.
  factory DependenciasPiloto.demo({AlmacenDemoProveedor? almacen}) {
    almacen ??= AlmacenDemoProveedor();
    return DependenciasPiloto(
      proveedor: DependenciasProveedor.demo(almacen),
      servicioAsignado: ServicioAsignadoDemo(almacen),
      sesionVuelo: fabricasSesionVueloDemo(almacen),
    );
  }

  final DependenciasProveedor proveedor;
  final ServicioAsignadoRepositorio servicioAsignado;

  /// Lo que arma la pantalla de sesión de vuelo de un servicio asignado.
  final FabricasSesionVuelo sesionVuelo;

  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      ...proveedor.proveedores,
      RepositoryProvider<ServicioAsignadoRepositorio>.value(
        value: servicioAsignado,
      ),
      RepositoryProvider<FabricasSesionVuelo>.value(value: sesionVuelo),
    ],
    child: child,
  );
}
