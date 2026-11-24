import 'package:flutter/widgets.dart';

import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';

/// Repositorios del flavor auxiliar: los del proveedor (ejecución del
/// servicio, drones y perfil; compartidos con `piloto`). El auxiliar no
/// negocia ni comparte ubicación: ve el servicio adjudicado de su equipo y
/// sube fotos de avance. La implementación demo (`MODO_DEMO`, ADR 0010) y la
/// real se eligen aquí.
class DependenciasAuxiliar {
  const DependenciasAuxiliar({required this.proveedor});

  factory DependenciasAuxiliar.demo({DependenciasProveedor? proveedor}) =>
      DependenciasAuxiliar(
        proveedor:
            proveedor ??
            DependenciasProveedor.demo(
              AlmacenDemoProveedor(),
              compartirUbicacion: false,
            ),
      );

  final DependenciasProveedor proveedor;

  Widget proveer({required Widget child}) => proveedor.proveer(child: child);
}
