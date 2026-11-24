import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../demo/almacen_demo_proveedor.dart';
import '../dron/data/drones_demo.dart';
import '../dron/domain/drones_repositorio.dart';
import '../ofertas/data/estado_red_demo.dart';
import '../ofertas/data/ofertas_demo.dart';
import '../ofertas/domain/estado_red.dart';
import '../ofertas/domain/ofertas_repositorio.dart';
import '../perfil/data/perfil_demo.dart';
import '../perfil/domain/perfil_repositorio.dart';

/// Repositorios de la superficie del proveedor (bandeja de ofertas, perfil y
/// drones). La montan los flavors `piloto` y `auxiliar` con el mismo código:
/// todo proveedor opera con los dos roles (ADR 0012).
class DependenciasProveedor {
  const DependenciasProveedor({
    required this.ofertas,
    required this.estadoRed,
    required this.drones,
    required this.perfil,
  });

  factory DependenciasProveedor.demo(AlmacenDemoProveedor almacen) =>
      DependenciasProveedor(
        ofertas: OfertasDemo(almacen),
        estadoRed: EstadoRedDemo(almacen),
        drones: DronesDemo(almacen),
        perfil: PerfilDemo(almacen),
      );

  final OfertasRepositorio ofertas;
  final EstadoRed estadoRed;
  final DronesRepositorio drones;
  final PerfilRepositorio perfil;

  /// Para sumarlos al `MultiRepositoryProvider` del flavor.
  List<RepositoryProvider<Object>> get proveedores => [
    RepositoryProvider<OfertasRepositorio>.value(value: ofertas),
    RepositoryProvider<EstadoRed>.value(value: estadoRed),
    RepositoryProvider<DronesRepositorio>.value(value: drones),
    RepositoryProvider<PerfilRepositorio>.value(value: perfil),
  ];

  Widget proveer({required Widget child}) =>
      MultiRepositoryProvider(providers: proveedores, child: child);
}
