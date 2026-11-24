import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import '../demo/almacen_demo_auxiliar.dart';
import '../mezcla/data/mezcla_demo.dart';
import '../mezcla/domain/mezcla_repositorio.dart';
import '../servicio_asignado/data/servicio_asignado_auxiliar_demo.dart';
import '../servicio_asignado/domain/servicio_asignado_auxiliar_repositorio.dart';

/// Repositorios del flavor auxiliar para la superficie del marketplace: los
/// del proveedor (ofertas, drones, perfil; compartidos con `piloto`), el
/// servicio asignado y la mezcla. La implementación demo (`MODO_DEMO`,
/// ADR 0010) y la real, que lee y escribe en `drift` con outbox, se eligen
/// aquí.
class DependenciasAuxiliar {
  const DependenciasAuxiliar({
    required this.proveedor,
    required this.servicioAsignado,
    required this.mezcla,
  });

  factory DependenciasAuxiliar.demo() {
    final almacen = AlmacenDemoAuxiliar();
    return DependenciasAuxiliar(
      proveedor: DependenciasProveedor.demo(
        AlmacenDemoProveedor(datos: almacen.datos),
      ),
      servicioAsignado: ServicioAsignadoAuxiliarDemo(almacen),
      mezcla: MezclaDemo(almacen),
    );
  }

  final DependenciasProveedor proveedor;
  final ServicioAsignadoAuxiliarRepositorio servicioAsignado;
  final MezclaRepositorio mezcla;

  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      ...proveedor.proveedores,
      RepositoryProvider<ServicioAsignadoAuxiliarRepositorio>.value(
        value: servicioAsignado,
      ),
      RepositoryProvider<MezclaRepositorio>.value(value: mezcla),
    ],
    child: child,
  );
}
