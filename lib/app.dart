import 'package:flutter/material.dart';

import 'features/auth/login_cubit.dart';
import 'features/auth/login_pantalla.dart';
import 'features/emergencia/presentation/emergencia_boton.dart';
import 'features/incidencias/presentation/incidencia_cubit.dart';
import 'features/inicio/presentation/inicio_cubit.dart';
import 'features/inicio/presentation/inicio_pantalla.dart';
import 'features/ordenes/presentation/ordenes_cubit.dart';
import 'features/ordenes/presentation/ordenes_pantalla.dart';
import 'features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/entorno/info_entorno.dart';
import 'nucleo/flavor.dart';
import 'nucleo/linterna/linterna_controlador.dart';
import 'nucleo/ui/colores_campo.dart';
import 'nucleo/ui/componentes/componentes_campo.dart';
import 'nucleo/ui/tema_campo.dart';
import 'nucleo/version/estado_version.dart';
import 'nucleo/version/version_bloqueo_overlay.dart';

/// App raíz de Agrocom — el nombre visible es siempre «Agrocom» (el logo
/// lleva el wordmark); `agrocom-field` es solo el nombre del repo/paquete.
///
/// Se instancia desde main_piloto.dart o main_auxiliar.dart según el flavor.
///
/// Tema único: el modo campo (ADR 0008, decisión del 1/10/2026), oscuro
/// siempre — no sigue `ThemeMode.system`, así ninguna pantalla, diálogo ni
/// panel sale con el Material claro de ADR 0003 según cómo tenga el sistema
/// el piloto o el auxiliar.
class AgrocomApp extends StatelessWidget {
  final Flavor flavor;
  final InfoEntorno infoEntorno;
  final TokenStore tokenStore;
  final LinternaControlador linternaControlador;
  final Stream<EstadoVersion> estadoVersion;
  final LoginCubit Function() crearLoginCubit;
  final OrdenesCubit Function() crearOrdenesCubit;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  /// Se llama una vez, justo después de un login exitoso (TE-19 ampliada) —
  /// hoy dispara `DisparadorSync.sincronizarAhora()`: el primer ciclo de
  /// sync corre al abrir la app, antes de que exista sesión, así que sin
  /// este segundo disparo un dispositivo recién logueado se queda sin
  /// catálogo hasta el próximo reinicio.
  final VoidCallback alIngresarConExito;

  /// Solo el flavor piloto la pasa (HU-70): con ella, la pantalla inicial
  /// tras el login es «Inicio» con el trabajo asignado, y las órdenes
  /// vigentes quedan como destino de su barra. Sin ella (auxiliar), la
  /// pantalla inicial sigue siendo la lista de órdenes.
  final InicioCubit Function()? crearInicioCubit;

  const AgrocomApp({
    required this.flavor,
    required this.infoEntorno,
    required this.tokenStore,
    required this.linternaControlador,
    required this.estadoVersion,
    required this.crearLoginCubit,
    required this.crearOrdenesCubit,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    required this.alIngresarConExito,
    this.crearInicioCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom',
      theme: AgrocomThemeCampo.construir(),
      home: VersionBloqueoOverlay(
        estadoVersion: estadoVersion,
        child: EmergenciaBoton(
          flavor: flavor,
          linternaControlador: linternaControlador,
          child: _RaizApp(
            flavor: flavor,
            infoEntorno: infoEntorno,
            tokenStore: tokenStore,
            crearLoginCubit: crearLoginCubit,
            crearOrdenesCubit: crearOrdenesCubit,
            crearTrabajoCubit: crearTrabajoCubit,
            crearSesionBloc: crearSesionBloc,
            crearIncidenciaCubit: crearIncidenciaCubit,
            alIngresarConExito: alIngresarConExito,
            crearInicioCubit: crearInicioCubit,
          ),
        ),
      ),
    );
  }
}

/// Decide, al arrancar, si hay que pedir login (`TokenStore.leerToken()` ==
/// null) o ir a la pantalla inicial: «Inicio» con el trabajo asignado en el
/// flavor piloto (HU-70), la lista de órdenes vigentes (HU-04) en el resto.
class _RaizApp extends StatefulWidget {
  const _RaizApp({
    required this.flavor,
    required this.infoEntorno,
    required this.tokenStore,
    required this.crearLoginCubit,
    required this.crearOrdenesCubit,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    required this.alIngresarConExito,
    required this.crearInicioCubit,
  });

  final Flavor flavor;
  final InfoEntorno infoEntorno;
  final TokenStore tokenStore;
  final LoginCubit Function() crearLoginCubit;
  final OrdenesCubit Function() crearOrdenesCubit;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;
  final VoidCallback alIngresarConExito;
  final InicioCubit Function()? crearInicioCubit;

  @override
  State<_RaizApp> createState() => _RaizAppState();
}

class _RaizAppState extends State<_RaizApp> {
  late Future<String?> _tokenInicial;
  bool _ingresoExitoso = false;

  @override
  void initState() {
    super.initState();
    _tokenInicial = widget.tokenStore.leerToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PantallaCarga();
        }

        if (snapshot.data == null && !_ingresoExitoso) {
          return LoginPantalla(
            crearCubit: widget.crearLoginCubit,
            infoEntorno: widget.infoEntorno,
            onIngresoExitoso: () {
              setState(() => _ingresoExitoso = true);
              widget.alIngresarConExito();
            },
          );
        }

        Widget ordenes(BuildContext _) => OrdenesPantalla(
          crearCubit: widget.crearOrdenesCubit,
          flavor: widget.flavor,
          crearTrabajoCubit: widget.crearTrabajoCubit,
          crearSesionBloc: widget.crearSesionBloc,
          crearIncidenciaCubit: widget.crearIncidenciaCubit,
        );

        final crearInicioCubit = widget.crearInicioCubit;
        if (widget.flavor == Flavor.piloto && crearInicioCubit != null) {
          return InicioPantalla(
            crearCubit: crearInicioCubit,
            crearTrabajoCubit: widget.crearTrabajoCubit,
            crearSesionBloc: widget.crearSesionBloc,
            crearIncidenciaCubit: widget.crearIncidenciaCubit,
            construirOrdenes: ordenes,
          );
        }
        return ordenes(context);
      },
    );
  }
}

/// Lo que se ve mientras se lee el token guardado: logo sobre
/// `fondoProfundo` y el indicador en el acento del tema — el mismo fondo que
/// el login que viene después, sin un destello claro en el medio.
class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('pantalla_carga'),
      backgroundColor: ColoresCampo.fondoProfundo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoAgrocomCampo(sombra: false),
            SizedBox(height: 32),
            CircularProgressIndicator(color: ColoresCampo.acentoLima),
          ],
        ),
      ),
    );
  }
}
