import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../camara/selector_imagen.dart';
import '../../../evidencias/compresor_adaptativo.dart';
import '../../../auth/bloqueo_biometrico.dart';
import '../../../auth/cuenta/data/cuenta_seguridad_demo.dart';
import '../../../auth/cuenta/domain/cuenta_seguridad.dart';
import '../../../notificaciones/push/dispositivos_push_repositorio.dart';
import '../../../permisos/data/gestor_permisos_plataforma.dart';
import '../../../permisos/domain/permiso.dart';
import '../../../notificaciones/push/token_push_store.dart';
import '../../../notificaciones/bandeja/data/bandeja_demo.dart';
import '../../../notificaciones/bandeja/data/bandeja_red.dart';
import '../../../notificaciones/bandeja/domain/bandeja_repositorio.dart';
import '../../../cuenta/data/contrasena_demo.dart';
import '../../../cuenta/data/contrasena_red.dart';
import '../../../cuenta/domain/contrasena_repositorio.dart';
import '../../foto_perfil/foto_perfil_repositorio.dart';
import '../../foto_preparador.dart';
import '../../pago/pagos_repositorio.dart';
import '../acceso/domain/acceso_proveedor.dart';
import '../cuenta/data/cuenta_proveedor_demo.dart';
import '../cuenta/data/cuenta_proveedor_red.dart';
import '../cuenta/domain/cuenta_proveedor.dart';
import '../demo/almacen_demo_proveedor.dart';
import '../dron/data/drones_demo.dart';
import '../dron/data/drones_red.dart';
import '../dron/domain/drones_repositorio.dart';
import '../ejecucion/di/dependencias_ejecucion.dart';
import '../ejecucion/domain/ejecucion.dart';
import '../negociacion/di/dependencias_negociacion.dart';
import '../../../cuenta/datos/data/datos_personales_demo.dart';
import '../../../cuenta/datos/data/datos_personales_red.dart';
import '../../../cuenta/datos/domain/datos_personales.dart';
import '../../../cuenta/datos/domain/datos_personales_repositorio.dart';
import '../perfil/data/perfil_demo.dart';
import '../perfil/data/perfil_red.dart';
import '../perfil/domain/perfil_repositorio.dart';
import '../../../api/marketplace_http.dart';

/// Repositorios de la superficie del proveedor: la negociación (mapa de
/// solicitudes, mis ofertas, chat y avisos), la ejecución del servicio
/// adjudicado, el perfil y los drones. La monta el flavor `piloto` (ADR 0012).
class DependenciasProveedor {
  DependenciasProveedor({
    required this.negociacion,
    required this.ejecucion,
    required this.drones,
    required this.perfil,
    required this.fotoPerfil,
    required this.pagos,
    required this.preparadorFoto,
    required this.push,
    CuentaProveedorRepositorio? cuenta,
    GestorPermisos? permisos,
    CuentaSeguridadRepositorio? seguridad,
    this.contrasena,
    this.datosPersonales,
    this.bandeja,
  }) : cuenta = cuenta ?? CuentaProveedorDemo(),
       permisos = permisos ?? GestorPermisosEnMemoria(),
       seguridad = seguridad ?? CuentaSeguridadDemo();

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
    bandeja: BandejaDemo(),
    datosPersonales: DatosPersonalesDemo(
      const DatosPersonales(
        nombre: 'Mamani Agroservicios',
        correo: 'contacto@mamani.example',
        telefono: '+591 7654 3210',
        documento: '4587123 SC',
      ),
    ),
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
    CuentaSeguridadRepositorio? seguridad,
  }) => DependenciasProveedor(
    negociacion: negociacion,
    ejecucion: ejecucion,
    drones: DronesRed(http),
    perfil: PerfilRed(http),
    fotoPerfil: FotoPerfilRed(http),
    datosPersonales: const DatosPersonalesRed(),
    contrasena: ContrasenaRed(http),
    bandeja: BandejaRed(http),
    pagos: PagosRed(http),
    preparadorFoto: PreparadorFoto(
      SelectorImagenImagePicker(),
      CompresorEvidenciaAdaptativo(),
    ),
    push: DispositivosPushRed(http, TokenPushStoreSeguro()),
    cuenta: CuentaProveedorRed(http),
    permisos: GestorPermisosPlataforma(),
    seguridad: seguridad,
  );

  final DependenciasNegociacion negociacion;
  final DependenciasEjecucion ejecucion;
  final DronesRepositorio drones;
  final PerfilRepositorio perfil;

  /// Foto de perfil de la cuenta del proveedor.
  final FotoPerfilRepositorio fotoPerfil;

  /// Cambio de contraseña con código; sin él Ajustes no ofrece la fila.
  final ContrasenaRepositorio? contrasena;

  /// Notificaciones recibidas (mensajes y avisos del sistema).
  final BandejaRepositorio? bandeja;

  /// Edición única de datos personales y solicitud de cambio; sin él (o con
  /// `disponible` falso) Ajustes no ofrece la fila.
  final DatosPersonalesRepositorio? datosPersonales;

  /// «Ya recibí el pago» del titular en el servicio finalizado.
  final PagosRepositorio pagos;

  /// Elige y comprime las fotos que se suben (perfil).
  final PreparadorFoto preparadorFoto;

  /// Token de push del aparato; se retira al cerrar sesión.
  final DispositivosPushRepositorio push;

  /// Estado de aprobación, documentos y disponibilidad (ADR 0024).
  final CuentaProveedorRepositorio cuenta;

  /// Permisos del sistema con su explicación previa (ADR 0026).
  final GestorPermisos permisos;

  /// Seguridad de la cuenta: recuperar el acceso, contraseña, teléfono y
  /// eliminar la cuenta (códigos por WhatsApp, SMS o correo).
  final CuentaSeguridadRepositorio seguridad;

  /// Para sumarlos al `MultiRepositoryProvider` del flavor.
  List<RepositoryProvider<Object>> get proveedores => [
    ...negociacion.proveedores,
    ...ejecucion.proveedores,
    RepositoryProvider<DronesRepositorio>.value(value: drones),
    RepositoryProvider<PerfilRepositorio>.value(value: perfil),
    RepositoryProvider<FotoPerfilRepositorio>.value(value: fotoPerfil),
    RepositoryProvider<PagosRepositorio>.value(value: pagos),
    RepositoryProvider<PreparadorFoto>.value(value: preparadorFoto),
    RepositoryProvider<CuentaProveedorRepositorio>.value(value: cuenta),
    RepositoryProvider<GestorPermisos>.value(value: permisos),
    RepositoryProvider<CuentaSeguridadRepositorio>.value(value: seguridad),
    // Antes de eliminar la cuenta hay que subir lo del lote.
    RepositoryProvider<PendientesDeSincronizacion>.value(
      value: _PendientesDelLote(ejecucion.repositorio),
    ),
    if (contrasena != null)
      RepositoryProvider<ContrasenaRepositorio>.value(value: contrasena!),
    if (bandeja != null)
      RepositoryProvider<BandejaRepositorio>.value(value: bandeja!),
    if (datosPersonales != null)
      RepositoryProvider<DatosPersonalesRepositorio>.value(
        value: datosPersonales!,
      ),
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
    this.bloqueo,
    this.renovarSesion,
  });

  final AccesoProveedorRepositorio acceso;
  final RegistroDronesRepositorio registroDrones;

  /// Avisa cuando el servidor revocó el token (`401`).
  final Stream<void>? sesionExpirada;

  /// Host y versión al pie del ingreso.
  final String? nota;

  /// Desbloqueo con huella o rostro (ADR 0026); sin él, la app entra directo
  /// con la sesión guardada.
  final BloqueoBiometrico? bloqueo;

  /// Renueva el token al desbloquear con la biometría si le quedan pocos
  /// días (`POST /api/auth/renovar`).
  final RenovadorSesion? renovarSesion;
}

/// Lo que el lote tiene sin subir, visto desde la eliminación de la cuenta.
class _PendientesDelLote implements PendientesDeSincronizacion {
  _PendientesDelLote(this._repositorio);

  final EjecucionRepositorio _repositorio;

  @override
  Future<int> cantidad() async {
    // Si la base no responde pronto, no se bloquea la pantalla: el servidor
    // sigue decidiendo.
    final servicios = await _repositorio.observar().first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => const <ServicioEnLote>[],
    );
    return servicios.fold<int>(0, (suma, s) => suma + s.pendientes);
  }

  @override
  Future<void> sincronizar() => _repositorio.sincronizarAhora();
}
