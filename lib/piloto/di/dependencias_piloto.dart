import 'package:flutter/widgets.dart';

import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';

/// Repositorios del flavor piloto: los del proveedor (mapa de solicitudes,
/// ofertas, ejecución del servicio, drones y perfil; compartidos con
/// `auxiliar`). La implementación demo (`MODO_DEMO`, ADR 0010) y la real se
/// eligen aquí.
class DependenciasPiloto {
  const DependenciasPiloto({required this.proveedor});

  /// [almacen] permite fijar los datos (y su reloj) desde una prueba.
  factory DependenciasPiloto.demo({
    AlmacenDemoProveedor? almacen,
    DependenciasProveedor? proveedor,
  }) => DependenciasPiloto(
    proveedor:
        proveedor ??
        DependenciasProveedor.demo(almacen ?? AlmacenDemoProveedor()),
  );

  final DependenciasProveedor proveedor;

  Widget proveer({required Widget child}) => proveedor.proveer(child: child);
}
