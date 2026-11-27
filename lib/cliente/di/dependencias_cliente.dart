import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/api/api_client.dart';
import '../../nucleo/conectividad/data/conectividad_falsa.dart';
import '../../nucleo/conectividad/data/conectividad_real.dart';
import '../../nucleo/conectividad/domain/conectividad_servicio.dart';
import '../../nucleo/auth/dispositivo_store.dart';
import '../../nucleo/api/marketplace_http.dart';
import '../../nucleo/auth/token_store.dart';
import '../../nucleo/camara/selector_imagen.dart';
import '../../nucleo/evidencias/compresor_adaptativo.dart';
import '../../nucleo/marketplace/foto_perfil/foto_perfil_repositorio.dart';
import '../../nucleo/marketplace/foto_preparador.dart';
import '../../nucleo/marketplace/pago/pago_confirmado.dart';
import '../../nucleo/marketplace/pago/pagos_repositorio.dart';
import '../../nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import '../../nucleo/notificaciones/push/dispositivos_push_repositorio.dart';
import '../../nucleo/notificaciones/push/token_push_store.dart';
import '../acceso/data/acceso_demo.dart';
import '../acceso/data/acceso_red.dart';
import '../acceso/domain/acceso_repositorio.dart';
import '../calificar/data/calificacion_demo.dart';
import '../calificar/data/calificacion_red.dart';
import '../calificar/domain/calificacion_repositorio.dart';
import '../comun/presentation/foto_remota.dart';
import '../../nucleo/cuenta/data/contrasena_demo.dart';
import '../../nucleo/cuenta/data/contrasena_red.dart';
import '../../nucleo/cuenta/domain/contrasena_repositorio.dart';
import '../contactos/data/contactos_demo.dart';
import '../contactos/data/contactos_red.dart';
import '../contactos/domain/contactos_repositorio.dart';
import '../cuenta/data/cuenta_demo.dart';
import '../cuenta/data/cuenta_red.dart';
import '../cuenta/domain/cuenta_repositorio.dart';
import '../demo/almacen_demo_cliente.dart';
import '../precio_final/data/precio_final_demo.dart';
import '../precio_final/data/precio_final_red.dart';
import '../precio_final/domain/precio_final_repositorio.dart';
import '../inicio/data/inicio_cliente_demo.dart';
import '../inicio/data/inicio_cliente_red.dart';
import '../inicio/domain/inicio_cliente_repositorio.dart';
import '../ofertas/data/ofertas_demo.dart';
import '../ofertas/data/ofertas_red.dart';
import '../ofertas/domain/ofertas_repositorio.dart';
import '../problema/data/problema_demo.dart';
import '../problema/data/problema_red.dart';
import '../problema/domain/problema_repositorio.dart';
import '../red/cliente_http.dart';
import '../red/fuente_solicitudes.dart';
import '../seguimiento/data/seguimiento_demo.dart';
import '../seguimiento/data/seguimiento_red.dart';
import '../seguimiento/domain/seguimiento_repositorio.dart';
import '../solicitar/data/solicitud_demo.dart';
import '../solicitar/data/solicitud_red.dart';
import '../solicitar/domain/solicitud_repositorio.dart';
import '../solicitudes/data/solicitudes_demo.dart';
import '../solicitudes/data/solicitudes_red.dart';
import '../solicitudes/domain/solicitudes_repositorio.dart';

/// Repositorios del flavor cliente. La interfaz de cada feature es lo único
/// que ven las pantallas; este contenedor decide qué implementación se usa.
///
/// El flavor cliente es online-first: no usa `drift`, `SyncEngine` ni outbox,
/// y por eso este archivo no importa `nucleo/db` ni `nucleo/sync` (ADR 0009,
/// regla 5; lo vigila `test/arquitectura/importaciones_test.dart`).
class DependenciasCliente {
  DependenciasCliente({
    required this.solicitudes,
    required this.solicitud,
    required this.ofertas,
    required this.seguimiento,
    required this.calificacion,
    required this.problema,
    required this.cuenta,
    required this.acceso,
    required this.inicio,
    required this.fotoPerfil,
    required this.fotosTerreno,
    required this.pagos,
    required this.preparadorFoto,
    required this.push,
    this.contactos,
    this.precioFinal,
    this.contrasena,
    this.notaAcceso,
    this.sesionExpirada,
    ConectividadServicio? conectividad,
  }) : conectividad = conectividad ?? ConectividadFalsa();

  /// Repositorios en memoria con datos ficticios (`MODO_DEMO`, ADR 0010).
  ///
  /// Por defecto la sesión ya está iniciada y la app abre en el inicio. Con
  /// [primerUso] arranca como recién instalada: presentación, acceso y
  /// después el inicio (así corre `main_cliente.dart` en modo demo), y los
  /// pilotos simulados responden: ofertan, contraofertan y contestan el chat.
  /// Con [almacen] y [latencia] las pruebas fijan los datos y quitan la
  /// espera simulada.
  factory DependenciasCliente.demo({
    bool primerUso = false,
    AlmacenDemoCliente? almacen,
    Duration? latencia,
    SelectorImagen? selectorImagen,
    PreparadorFoto? preparadorFoto,
    PagosRepositorio? pagos,
  }) {
    almacen ??= AlmacenDemoCliente(respuestasAutomaticas: primerUso);
    return DependenciasCliente(
      solicitudes: latencia == null
          ? SolicitudesDemo(almacen)
          : SolicitudesDemo(almacen, latencia: latencia),
      solicitud: latencia == null
          ? SolicitudDemo(almacen)
          : SolicitudDemo(almacen, latencia: latencia),
      ofertas: latencia == null
          ? OfertasDemo(almacen)
          : OfertasDemo(almacen, latencia: latencia),
      seguimiento: latencia == null
          ? SeguimientoDemo(almacen)
          : SeguimientoDemo(almacen, latencia: latencia),
      calificacion: latencia == null
          ? CalificacionDemo(almacen)
          : CalificacionDemo(almacen, latencia: latencia),
      problema: latencia == null
          ? ProblemaDemo(almacen)
          : ProblemaDemo(almacen, latencia: latencia),
      cuenta: CuentaDemo(almacen),
      acceso: AccesoDemo(
        almacen,
        onboardingVisto: !primerUso,
        sesionIniciada: !primerUso,
      ),
      inicio: InicioClienteDemo(almacen),
      fotoPerfil: FotoPerfilDemo(),
      fotosTerreno: FotosTerrenoDemo(),
      pagos: pagos ?? _pagosDemo(almacen),
      preparadorFoto:
          preparadorFoto ??
          PreparadorFoto(
            selectorImagen ?? SelectorImagenImagePicker(),
            CompresorEvidenciaAdaptativo(),
          ),
      push: DispositivosPushDemo(TokenPushEnMemoria()),
      contactos: ContactosDemo(),
      contrasena: ContrasenaDemo(),
      precioFinal: PrecioFinalDemo(almacen),
      notaAcceso:
          'Modo demo: ingresa con cualquier usuario y una contraseña de 8 '
          'caracteres o más. Los datos son ficticios.',
    );
  }

  /// El pago de la solicitud finalizada de la demo ya está confirmado por
  /// el piloto, para que el seguimiento muestre «Pago confirmado».
  static PagosRepositorio _pagosDemo(AlmacenDemoCliente almacen) {
    final lote = almacen.datos.lotes[2];
    return PagosDemo(
      previos: [
        PagoConfirmado(
          id: 1,
          uuidCliente: 'demo-pago-4103',
          solicitudId: 4103,
          monto: lote.hectareas * Decimal.fromInt(125),
          metodo: MetodoPago.transferencia,
          confirmadoEn: almacen.ahora.subtract(const Duration(hours: 3)),
        ),
      ],
    );
  }

  /// Repositorios que hablan con la API (online-first, sin `drift` ni
  /// outbox). El token vive en [tokenStore] (Keychain/Keystore). Cuando un
  /// request autenticado recibe `401`, se borra el token, se descartan los
  /// datos en memoria y [sesionExpirada] avisa para volver al acceso.
  factory DependenciasCliente.red({
    required ApiClient api,
    required TokenStore tokenStore,
    required DispositivoStore dispositivoStore,
    OnboardingStore? onboarding,
    String? notaAcceso,
  }) {
    final http = ClienteHttp(api);
    final fuente = FuenteSolicitudes(http, ZonasRed(http));
    final cuenta = CuentaRed(http);
    final marketplace = MarketplaceHttp(api);
    final push = DispositivosPushRed(marketplace, TokenPushStoreSeguro());
    final expiracion = StreamController<void>.broadcast();
    void olvidar() {
      fuente.olvidar();
      FotoRemota.limpiarCache();
    }

    api.alSesionExpirada = () {
      unawaited(tokenStore.borrarToken());
      olvidar();
      expiracion.add(null);
    };
    return DependenciasCliente(
      solicitudes: SolicitudesRed(http, fuente),
      solicitud: SolicitudRed(http, fuente),
      ofertas: OfertasRed(http, fuente),
      seguimiento: SeguimientoRed(http),
      calificacion: CalificacionRed(http, fuente),
      problema: ProblemaRed(http, fuente),
      cuenta: cuenta,
      acceso: AccesoRed(
        api: api,
        tokenStore: tokenStore,
        dispositivoStore: dispositivoStore,
        onboarding: onboarding ?? OnboardingStoreLocal(),
        alCerrarSesion: olvidar,
        retirarPush: push.retirar,
      ),
      inicio: InicioClienteRed(fuente, http, cuenta),
      fotoPerfil: FotoPerfilRed(marketplace),
      fotosTerreno: FotosTerrenoRed(marketplace),
      pagos: PagosRed(marketplace),
      preparadorFoto: PreparadorFoto(
        SelectorImagenImagePicker(),
        CompresorEvidenciaAdaptativo(),
      ),
      push: push,
      contactos: ContactosRed(http),
      contrasena: ContrasenaRed(marketplace),
      precioFinal: PrecioFinalRed(http),
      notaAcceso: notaAcceso,
      sesionExpirada: expiracion.stream,
      conectividad: ConectividadReal(),
    );
  }

  final SolicitudesRepositorio solicitudes;
  final SolicitudRepositorio solicitud;
  final OfertasRepositorio ofertas;
  final SeguimientoRepositorio seguimiento;
  final CalificacionRepositorio calificacion;
  final ProblemaRepositorio problema;
  final CuentaRepositorio cuenta;
  final AccesoRepositorio acceso;
  final InicioClienteRepositorio inicio;

  /// Foto de perfil de la cuenta.
  final FotoPerfilRepositorio fotoPerfil;

  /// Fotos de los terrenos del cliente (hasta 8 por terreno).
  final FotosTerrenoRepositorio fotosTerreno;

  /// El pago confirmado por el proveedor, de solo lectura para el cliente.
  final PagosRepositorio pagos;

  /// Elige y comprime las fotos que se suben.
  final PreparadorFoto preparadorFoto;

  /// Token de push del aparato; se retira al cerrar sesión.
  final DispositivosPushRepositorio push;

  /// Contactos de referencia del cliente empresa; sin él, el cliente no los
  /// gestiona (las pruebas que no los necesitan lo omiten).
  final ContactosRepositorio? contactos;

  /// Cambio de contraseña con código; sin él Ajustes no ofrece la fila.
  final ContrasenaRepositorio? contrasena;

  /// Precio final y su confirmación; sin él la pantalla muestra solo lo de
  /// la solicitud.
  final PrecioFinalRepositorio? precioFinal;

  /// Nota que la pantalla de ingreso muestra bajo el formulario; solo la
  /// define el modo demo.
  final String? notaAcceso;

  /// Avisa cuando la sesión venció o se revocó (`401`); solo lo define la
  /// implementación de red.
  final Stream<void>? sesionExpirada;

  /// Estado de la red para el banner «Sin señal»: falsa en demo y pruebas,
  /// real en la implementación de red.
  final ConectividadServicio conectividad;

  /// Expone los repositorios al árbol de widgets.
  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SolicitudesRepositorio>.value(value: solicitudes),
      RepositoryProvider<SolicitudRepositorio>.value(value: solicitud),
      RepositoryProvider<OfertasRepositorio>.value(value: ofertas),
      RepositoryProvider<SeguimientoRepositorio>.value(value: seguimiento),
      RepositoryProvider<CalificacionRepositorio>.value(value: calificacion),
      RepositoryProvider<ProblemaRepositorio>.value(value: problema),
      RepositoryProvider<CuentaRepositorio>.value(value: cuenta),
      RepositoryProvider<AccesoRepositorio>.value(value: acceso),
      RepositoryProvider<InicioClienteRepositorio>.value(value: inicio),
      RepositoryProvider<FotoPerfilRepositorio>.value(value: fotoPerfil),
      RepositoryProvider<FotosTerrenoRepositorio>.value(value: fotosTerreno),
      RepositoryProvider<PagosRepositorio>.value(value: pagos),
      RepositoryProvider<PreparadorFoto>.value(value: preparadorFoto),
      if (precioFinal != null)
        RepositoryProvider<PrecioFinalRepositorio>.value(value: precioFinal!),
      if (contactos != null)
        RepositoryProvider<ContactosRepositorio>.value(value: contactos!),
      if (contrasena != null)
        RepositoryProvider<ContrasenaRepositorio>.value(value: contrasena!),
    ],
    child: child,
  );
}
