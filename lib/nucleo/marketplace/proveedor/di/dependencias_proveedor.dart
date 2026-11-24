import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../acceso/domain/acceso_proveedor.dart';
import '../demo/almacen_demo_proveedor.dart';
import '../dron/data/drones_demo.dart';
import '../dron/data/drones_red.dart';
import '../dron/domain/drones_repositorio.dart';
import '../ejecucion/di/dependencias_ejecucion.dart';
import '../negociacion/di/dependencias_negociacion.dart';
import '../perfil/data/perfil_demo.dart';
import '../perfil/data/perfil_red.dart';
import '../perfil/domain/perfil_repositorio.dart';
import '../../../api/marketplace_http.dart';

/// Repositorios de la superficie del proveedor: la negociación (mapa de
/// solicitudes, mis ofertas, chat y avisos), la ejecución del servicio
/// adjudicado, el perfil y los drones. La montan los flavors `piloto` y
/// `auxiliar` con el mismo código: todo proveedor opera con los dos roles
/// (ADR 0012).
class DependenciasProveedor {
  const DependenciasProveedor({
    required this.negociacion,
    required this.ejecucion,
    required this.drones,
    required this.perfil,
  });

  factory DependenciasProveedor.demo(
    AlmacenDemoProveedor almacen, {
    DependenciasNegociacion? negociacion,
    DependenciasEjecucion? ejecucion,
    bool compartirUbicacion = true,
  }) => DependenciasProveedor(
    negociacion: negociacion ?? DependenciasNegociacion.demo(),
    ejecucion:
        ejecucion ??
        DependenciasEjecucion.demo(compartirUbicacion: compartirUbicacion),
    drones: DronesDemo(almacen),
    perfil: PerfilDemo(almacen),
  );

  /// Contra la API: perfil y drones por red; la negociación y la ejecución
  /// las arma quien compone la app (necesitan la base local y la cámara).
  factory DependenciasProveedor.red(
    MarketplaceHttp http, {
    required DependenciasNegociacion negociacion,
    required DependenciasEjecucion ejecucion,
  }) => DependenciasProveedor(
    negociacion: negociacion,
    ejecucion: ejecucion,
    drones: DronesRed(http),
    perfil: PerfilRed(http),
  );

  final DependenciasNegociacion negociacion;
  final DependenciasEjecucion ejecucion;
  final DronesRepositorio drones;
  final PerfilRepositorio perfil;

  /// Para sumarlos al `MultiRepositoryProvider` del flavor.
  List<RepositoryProvider<Object>> get proveedores => [
    ...negociacion.proveedores,
    ...ejecucion.proveedores,
    RepositoryProvider<DronesRepositorio>.value(value: drones),
    RepositoryProvider<PerfilRepositorio>.value(value: perfil),
  ];

  Widget proveer({required Widget child}) =>
      MultiRepositoryProvider(providers: proveedores, child: child);
}

/// Lo que la app real necesita además de la superficie: el acceso y el alta.
class DependenciasAccesoProveedor {
  const DependenciasAccesoProveedor({
    required this.acceso,
    required this.registroDrones,
    this.sesionExpirada,
    this.nota,
  });

  final AccesoProveedorRepositorio acceso;
  final RegistroDronesRepositorio registroDrones;

  /// Avisa cuando el servidor revocó el token (`401`).
  final Stream<void>? sesionExpirada;

  /// Host y versión al pie del ingreso.
  final String? nota;
}
