import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../camara/selector_imagen.dart';
import '../../../evidencias/compresor_adaptativo.dart';
import '../../../notificaciones/push/dispositivos_push_repositorio.dart';
import '../../../notificaciones/push/token_push_store.dart';
import '../../../cuenta/data/contrasena_demo.dart';
import '../../../cuenta/data/contrasena_red.dart';
import '../../../cuenta/domain/contrasena_repositorio.dart';
import '../../foto_perfil/foto_perfil_repositorio.dart';
import '../../foto_preparador.dart';
import '../../pago/pagos_repositorio.dart';
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
/// adjudicado, el perfil y los drones. La monta el flavor `piloto` (ADR 0012).
class DependenciasProveedor {
  const DependenciasProveedor({
    required this.negociacion,
    required this.ejecucion,
    required this.drones,
    required this.perfil,
    required this.fotoPerfil,
    required this.pagos,
    required this.preparadorFoto,
    required this.push,
    this.contrasena,
  });

  factory DependenciasProveedor.demo(
    AlmacenDemoProveedor almacen, {
    DependenciasNegociacion? negociacion,
    DependenciasEjecucion? ejecucion,
    bool compartirUbicacion = true,
    SelectorImagen? selectorImagen,
    PreparadorFoto? preparadorFoto,
    PagosRepositorio? pagos,
  }) => DependenciasProveedor(
    negociacion: negociacion ?? DependenciasNegociacion.demo(),
    ejecucion:
        ejecucion ??
        DependenciasEjecucion.demo(compartirUbicacion: compartirUbicacion),
    drones: DronesDemo(almacen),
    perfil: PerfilDemo(almacen),
    fotoPerfil: FotoPerfilDemo(),
    contrasena: ContrasenaDemo(),
    pagos:
        pagos ??
        PagosDemo(
          montos: {10: Decimal.parse('9200'), 9: Decimal.parse('14880')},
        ),
    preparadorFoto:
        preparadorFoto ??
        PreparadorFoto(
          selectorImagen ?? SelectorImagenImagePicker(),
          CompresorEvidenciaAdaptativo(),
        ),
    push: DispositivosPushDemo(TokenPushEnMemoria()),
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
    fotoPerfil: FotoPerfilRed(http),
    contrasena: ContrasenaRed(http),
    pagos: PagosRed(http),
    preparadorFoto: PreparadorFoto(
      SelectorImagenImagePicker(),
      CompresorEvidenciaAdaptativo(),
    ),
    push: DispositivosPushRed(http, TokenPushStoreSeguro()),
  );

  final DependenciasNegociacion negociacion;
  final DependenciasEjecucion ejecucion;
  final DronesRepositorio drones;
  final PerfilRepositorio perfil;

  /// Foto de perfil de la cuenta del proveedor.
  final FotoPerfilRepositorio fotoPerfil;

  /// Cambio de contraseña con código; sin él Ajustes no ofrece la fila.
  final ContrasenaRepositorio? contrasena;

  /// «Ya recibí el pago» del titular en el servicio finalizado.
  final PagosRepositorio pagos;

  /// Elige y comprime las fotos que se suben (perfil).
  final PreparadorFoto preparadorFoto;

  /// Token de push del aparato; se retira al cerrar sesión.
  final DispositivosPushRepositorio push;

  /// Para sumarlos al `MultiRepositoryProvider` del flavor.
  List<RepositoryProvider<Object>> get proveedores => [
    ...negociacion.proveedores,
    ...ejecucion.proveedores,
    RepositoryProvider<DronesRepositorio>.value(value: drones),
    RepositoryProvider<PerfilRepositorio>.value(value: perfil),
    RepositoryProvider<FotoPerfilRepositorio>.value(value: fotoPerfil),
    RepositoryProvider<PagosRepositorio>.value(value: pagos),
    RepositoryProvider<PreparadorFoto>.value(value: preparadorFoto),
    if (contrasena != null)
      RepositoryProvider<ContrasenaRepositorio>.value(value: contrasena!),
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
