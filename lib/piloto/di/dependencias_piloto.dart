import 'package:flutter/widgets.dart';

import '../../nucleo/conectividad/data/conectividad_falsa.dart';
import '../../nucleo/conectividad/domain/conectividad_servicio.dart';
import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import '../../nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';

/// Repositorios del flavor piloto: los del proveedor (mapa de solicitudes,
/// ofertas, ejecución del servicio, drones y perfil). La implementación demo (`MODO_DEMO`, ADR 0010) y la real se
/// eligen aquí.
class DependenciasPiloto {
  DependenciasPiloto({
    required this.proveedor,
    ConectividadServicio? conectividad,
  }) : conectividad = conectividad ?? ConectividadFalsa();

  /// [almacen] permite fijar los datos (y su reloj) desde una prueba.
  factory DependenciasPiloto.demo({
    AlmacenDemoProveedor? almacen,
    DependenciasProveedor? proveedor,
    ConectividadServicio? conectividad,
  }) => DependenciasPiloto(
    proveedor:
        proveedor ??
        DependenciasProveedor.demo(almacen ?? AlmacenDemoProveedor()),
    conectividad: conectividad,
  );

  final DependenciasProveedor proveedor;

  /// Falsa por defecto (demo y pruebas); la real solo la monta `main_piloto`.
  final ConectividadServicio conectividad;

  Widget proveer({required Widget child}) => proveedor.proveer(child: child);
}
