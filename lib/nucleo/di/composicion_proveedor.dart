import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_client.dart';
import '../api/marketplace_http.dart';
import '../auth/dispositivo_store.dart';
import '../auth/token_store.dart';
import '../camara/selector_foto.dart';
import '../camara/selector_imagen.dart';
import '../db/database.dart';
import '../entorno/api_base_url.dart';
import '../entorno/info_entorno.dart';
import '../evidencias/compresor_adaptativo.dart';
import '../evidencias/directorio_evidencias.dart';
import '../flavor.dart';
import '../marketplace/proveedor/acceso/data/acceso_proveedor_red.dart';
import '../marketplace/proveedor/di/dependencias_proveedor.dart';
import '../marketplace/proveedor/ejecucion/di/dependencias_ejecucion.dart';
import '../marketplace/proveedor/negociacion/di/dependencias_negociacion.dart';
import '../notificaciones/notificador_local.dart';

/// Todo lo que la app real de `piloto` o `auxiliar` necesita: la superficie
/// del proveedor (negociación, ejecución, perfil y drones), el acceso y el
/// alta, y el selector de imágenes.
class ComposicionProveedor {
  const ComposicionProveedor({
    required this.proveedor,
    required this.acceso,
    required this.selectorImagen,
  });

  final DependenciasProveedor proveedor;
  final DependenciasAccesoProveedor acceso;
  final SelectorImagen selectorImagen;
}

/// Raíz de composición de la app real (fuera de `MODO_DEMO`): cablea la API,
/// la base local `drift`, la cámara y las notificaciones locales. El flavor
/// `cliente` no pasa por acá (online-first, sin `drift`).
///
/// El motor de subida de la ejecución (`EjecucionSyncEngine`) corre al abrir
/// la app, al volver la conectividad y cuando el piloto pide actualizar.
///
/// [selectorFoto] reemplaza la cámara real; solo lo usan las pruebas de
/// integración, porque el simulador no tiene cámara.
Future<ComposicionProveedor> componerProveedor(
  Flavor flavor, {
  SelectorFoto? selectorFoto,
}) async {
  final tokenStore = TokenStoreSeguro();
  final api = ApiClient(baseUrl: apiBaseUrl, tokenStore: tokenStore);
  final http = MarketplaceHttp(api);
  final db = AppDatabase();
  final directorio = await resolverDirectorioEvidencias();
  final paquete = await PackageInfo.fromPlatform();
  final info = InfoEntorno(
    flavor: flavor,
    hostApi: InfoEntorno.hostDe(apiBaseUrl),
    version: '${paquete.version}+${paquete.buildNumber}',
  );

  final esPiloto = flavor == Flavor.piloto;
  final ejecucion = DependenciasEjecucion.local(
    db: db,
    api: api,
    compresor: CompresorEvidenciaAdaptativo(),
    directorioFotos: directorio,
    selectorFoto: selectorFoto ?? SelectorFotoImagePicker(),
    compartirUbicacion: esPiloto,
  );
  final negociacion = DependenciasNegociacion.red(
    http,
    notificador: NotificadorLocalPlugin(),
  );

  // Un token vencido o revocado (`401`) devuelve al ingreso.
  final expiracion = StreamController<void>.broadcast();
  api.alSesionExpirada = () {
    unawaited(tokenStore.borrarToken());
    expiracion.add(null);
  };

  // Lo pendiente de subir sale al abrir la app y al volver la señal.
  final motor = ejecucion.motor;
  if (motor != null) {
    unawaited(motor.sincronizar());
    Connectivity().onConnectivityChanged.listen((estado) {
      if (!estado.contains(ConnectivityResult.none)) {
        unawaited(motor.sincronizar());
      }
    });
  }

  return ComposicionProveedor(
    proveedor: DependenciasProveedor.red(
      http,
      negociacion: negociacion,
      ejecucion: ejecucion,
    ),
    acceso: DependenciasAccesoProveedor(
      acceso: AccesoProveedorRed(
        api: api,
        tokenStore: tokenStore,
        dispositivoStore: DispositivoStoreSeguro(),
        rolesPreferidos: esPiloto
            ? const ['proveedor', 'piloto']
            : const ['auxiliar'],
        nombreDispositivo: esPiloto ? 'Agrocom Piloto' : 'Agrocom Auxiliar',
        alCerrarSesion: ejecucion.repositorio.limpiarAlCerrarSesion,
      ),
      registroDrones: RegistroDronesRed(http),
      sesionExpirada: expiracion.stream,
      nota: 'Servidor ${info.hostApi} · v${info.version}',
    ),
    selectorImagen: SelectorImagenImagePicker(),
  );
}
