import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/api/api_client.dart';
import '../../nucleo/auth/dispositivo_store.dart';
import '../../nucleo/auth/token_store.dart';
import '../acceso/data/acceso_demo.dart';
import '../acceso/data/acceso_red.dart';
import '../acceso/domain/acceso_repositorio.dart';
import '../calificar/data/calificacion_demo.dart';
import '../calificar/data/calificacion_red.dart';
import '../calificar/domain/calificacion_repositorio.dart';
import '../conformidad/data/conformidad_demo.dart';
import '../conformidad/data/conformidad_red.dart';
import '../conformidad/domain/conformidad_repositorio.dart';
import '../cuenta/data/cuenta_demo.dart';
import '../cuenta/data/cuenta_red.dart';
import '../cuenta/domain/cuenta_repositorio.dart';
import '../demo/almacen_demo_cliente.dart';
import '../inicio/data/inicio_cliente_demo.dart';
import '../inicio/data/inicio_cliente_red.dart';
import '../inicio/domain/inicio_cliente_repositorio.dart';
import '../problema/data/problema_demo.dart';
import '../problema/data/problema_red.dart';
import '../red/cliente_http.dart';
import '../red/fuente_servicios.dart';
import '../problema/domain/problema_repositorio.dart';
import '../seguimiento/data/seguimiento_demo.dart';
import '../seguimiento/data/seguimiento_red.dart';
import '../seguimiento/domain/seguimiento_repositorio.dart';
import '../servicios/data/servicios_cliente_demo.dart';
import '../servicios/data/servicios_cliente_red.dart';
import '../servicios/domain/servicios_cliente_repositorio.dart';
import '../solicitar/data/solicitud_demo.dart';
import '../solicitar/data/solicitud_red.dart';
import '../solicitar/domain/solicitud_repositorio.dart';

/// Repositorios del flavor cliente. La interfaz de cada feature es lo único
/// que ven las pantallas; este contenedor decide qué implementación se usa.
///
/// El flavor cliente es online-first: no usa `drift`, `SyncEngine` ni outbox,
/// y por eso este archivo no importa `nucleo/db` ni `nucleo/sync` (ADR 0009,
/// regla 5; lo vigila `test/arquitectura/importaciones_test.dart`).
class DependenciasCliente {
  const DependenciasCliente({
    required this.servicios,
    required this.solicitud,
    required this.seguimiento,
    required this.calificacion,
    required this.conformidad,
    required this.problema,
    required this.cuenta,
    required this.acceso,
    required this.inicio,
    this.notaAcceso,
    this.sesionExpirada,
  });

  /// Repositorios en memoria con datos ficticios (`MODO_DEMO`, ADR 0010).
  ///
  /// Por defecto la sesión ya está iniciada y la app abre en el inicio. Con
  /// [primerUso] arranca como recién instalada: presentación, acceso y
  /// después el inicio (así corre `main_cliente.dart` en modo demo). Con
  /// [almacen] y [latencia] las pruebas fijan los datos y quitan la espera
  /// simulada.
  factory DependenciasCliente.demo({
    bool primerUso = false,
    AlmacenDemoCliente? almacen,
    Duration? latencia,
  }) {
    almacen ??= AlmacenDemoCliente();
    return DependenciasCliente(
      servicios: ServiciosClienteDemo(almacen),
      solicitud: SolicitudDemo(almacen),
      seguimiento: SeguimientoDemo(almacen),
      calificacion: latencia == null
          ? CalificacionDemo(almacen)
          : CalificacionDemo(almacen, latencia: latencia),
      conformidad: latencia == null
          ? ConformidadDemo(almacen)
          : ConformidadDemo(almacen, latencia: latencia),
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
      notaAcceso:
          'Modo demo: entra con cualquier usuario y una contraseña de 8 '
          'caracteres o más. Los datos son ficticios.',
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
    final fuente = FuenteServicios(http, ZonasRed(http));
    final cuenta = CuentaRed(http);
    final expiracion = StreamController<void>.broadcast();
    api.alSesionExpirada = () {
      unawaited(tokenStore.borrarToken());
      fuente.olvidar();
      expiracion.add(null);
    };
    return DependenciasCliente(
      servicios: ServiciosClienteRed(fuente),
      solicitud: SolicitudRed(http, fuente),
      seguimiento: SeguimientoRed(fuente),
      calificacion: CalificacionRed(http, fuente),
      conformidad: ConformidadRed(http, fuente),
      problema: ProblemaRed(http, fuente),
      cuenta: cuenta,
      acceso: AccesoRed(
        api: api,
        tokenStore: tokenStore,
        dispositivoStore: dispositivoStore,
        onboarding: onboarding ?? OnboardingStoreLocal(),
        alCerrarSesion: fuente.olvidar,
      ),
      inicio: InicioClienteRed(fuente, http, cuenta),
      notaAcceso: notaAcceso,
      sesionExpirada: expiracion.stream,
    );
  }

  final ServiciosClienteRepositorio servicios;
  final SolicitudRepositorio solicitud;
  final SeguimientoRepositorio seguimiento;
  final CalificacionRepositorio calificacion;
  final ConformidadRepositorio conformidad;
  final ProblemaRepositorio problema;
  final CuentaRepositorio cuenta;
  final AccesoRepositorio acceso;
  final InicioClienteRepositorio inicio;

  /// Nota que la pantalla de ingreso muestra bajo el formulario; solo la
  /// define el modo demo.
  final String? notaAcceso;

  /// Avisa cuando la sesión venció o se revocó (`401`); solo lo define la
  /// implementación de red.
  final Stream<void>? sesionExpirada;

  /// Expone los repositorios al árbol de widgets.
  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ServiciosClienteRepositorio>.value(value: servicios),
      RepositoryProvider<SolicitudRepositorio>.value(value: solicitud),
      RepositoryProvider<SeguimientoRepositorio>.value(value: seguimiento),
      RepositoryProvider<CalificacionRepositorio>.value(value: calificacion),
      RepositoryProvider<ConformidadRepositorio>.value(value: conformidad),
      RepositoryProvider<ProblemaRepositorio>.value(value: problema),
      RepositoryProvider<CuentaRepositorio>.value(value: cuenta),
      RepositoryProvider<AccesoRepositorio>.value(value: acceso),
      RepositoryProvider<InicioClienteRepositorio>.value(value: inicio),
    ],
    child: child,
  );
}
