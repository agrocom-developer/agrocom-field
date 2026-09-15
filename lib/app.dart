import 'package:flutter/material.dart';

import 'features/auth/login_cubit.dart';
import 'features/auth/login_pantalla.dart';
import 'features/emergencia/presentation/emergencia_boton.dart';
import 'features/incidencias/presentation/incidencia_cubit.dart';
import 'features/ordenes/presentation/ordenes_cubit.dart';
import 'features/ordenes/presentation/ordenes_pantalla.dart';
import 'features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/entorno/info_entorno.dart';
import 'nucleo/flavor.dart';
import 'nucleo/linterna/linterna_controlador.dart';
import 'nucleo/ui/tema.dart';
import 'nucleo/version/estado_version.dart';
import 'nucleo/version/version_bloqueo_overlay.dart';

/// App raíz de Agrocom — el nombre visible es siempre «Agrocom» (el logo
/// lleva el wordmark); `agrocom-field` es solo el nombre del repo/paquete.
///
/// Se instancia desde main_piloto.dart o main_auxiliar.dart según el flavor.
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom',
      theme: AgrocomTheme.light(),
      darkTheme: AgrocomTheme.dark(),
      themeMode: ThemeMode.system,
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
          ),
        ),
      ),
    );
  }
}

/// Decide, al arrancar, si hay que pedir login (`TokenStore.leerToken()` ==
/// null) o ir directo a la lista de órdenes vigentes (HU-04) — HU-03 solo
/// cubre esa bifurcación, nunca decidió qué pantalla "home" mostrar.
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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

        return OrdenesPantalla(
          crearCubit: widget.crearOrdenesCubit,
          flavor: widget.flavor,
          crearTrabajoCubit: widget.crearTrabajoCubit,
          crearSesionBloc: widget.crearSesionBloc,
          crearIncidenciaCubit: widget.crearIncidenciaCubit,
        );
      },
    );
  }
}
