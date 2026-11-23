import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import '../servicio_asignado/data/servicio_asignado_demo.dart';
import '../servicio_asignado/domain/servicio_asignado_repositorio.dart';

/// Repositorios del flavor piloto para la superficie del marketplace: los
/// del proveedor (ofertas, drones, perfil; compartidos con `auxiliar`) y el
/// servicio asignado. La implementación demo (`MODO_DEMO`, ADR 0010) y la
/// real se eligen aquí.
class DependenciasPiloto {
  const DependenciasPiloto({
    required this.proveedor,
    required this.servicioAsignado,
  });

  factory DependenciasPiloto.demo() {
    final almacen = AlmacenDemoProveedor();
    return DependenciasPiloto(
      proveedor: DependenciasProveedor.demo(almacen),
      servicioAsignado: ServicioAsignadoDemo(almacen),
    );
  }

  final DependenciasProveedor proveedor;
  final ServicioAsignadoRepositorio servicioAsignado;

  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      ...proveedor.proveedores,
      RepositoryProvider<ServicioAsignadoRepositorio>.value(
        value: servicioAsignado,
      ),
    ],
    child: child,
  );
}
