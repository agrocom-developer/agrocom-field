import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../nucleo/conectividad/data/conectividad_falsa.dart';
import '../nucleo/conectividad/domain/conectividad_servicio.dart';
import '../nucleo/conectividad/presentation/con_banner_de_red.dart';
import '../nucleo/marketplace/proveedor/dron/presentation/drones_pantalla.dart';
import '../nucleo/marketplace/proveedor/ejecucion/presentation/servicios_lote_pantalla.dart';
import '../nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart';
import '../nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_pantalla.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/perfil_pantalla.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/paleta_campo.dart';
import '../nucleo/ui/tema_visual/tema_visual_app.dart';
import 'di/dependencias_piloto.dart';

/// Superficie del marketplace del flavor piloto con datos ficticios
/// (`MODO_DEMO`, ADR 0010). Tema modo campo (alto contraste, objetivos de
/// 56 px). La misma [ShellPiloto] la monta la app real (`AppPiloto`) con los
/// repositorios de red.
class AppPilotoDemo extends StatefulWidget {
  const AppPilotoDemo({required this.dependencias, super.key});

  final DependenciasPiloto dependencias;

  @override
  State<AppPilotoDemo> createState() => _AppPilotoDemoState();
}

class _AppPilotoDemoState extends State<AppPilotoDemo> {
  final _navegador = GlobalKey<NavigatorState>();

  DependenciasPiloto get dependencias => widget.dependencias;

  /// La demo no tiene sesión: «Cerrar sesión» vuelve al inicio con un shell
  /// nuevo, para poder ver el flujo.
  void _reiniciar() {
    _navegador.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => _shell()),
      (_) => false,
    );
  }

  Widget _shell() =>
      ShellPiloto(conectividad: dependencias.conectividad, alSalir: _reiniciar);

  @override
  Widget build(BuildContext context) {
    return TemaVisualApp(
      predeterminado: ModoVisualCampo.claro,
      construir: (context, tema) => MaterialApp(
        navigatorKey: _navegador,
        title: 'Agrocom',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        debugShowCheckedModeBanner: false,
        theme: tema.claro,
        darkTheme: tema.oscuro,
        themeMode: tema.modo,
        // Los repositorios van por encima del `Navigator`: las rutas que se
        // apilan (detalle, seguimiento) los heredan.
        builder: (context, child) => dependencias.proveer(child: child!),
        home: _shell(),
      ),
    );
  }
}

/// Navegación del piloto: el mapa de solicitudes abiertas, sus ofertas, sus
/// servicios adjudicados y el perfil (que lleva el dron y la licencia).
class ShellPiloto extends StatefulWidget {
  const ShellPiloto({this.conectividad, this.alSalir, super.key});

  /// Estado de la red para el banner «Sin señal»; sin él, siempre hay red.
  final ConectividadServicio? conectividad;

  /// Cierra la sesión. En la demo reinicia el recorrido.
  final VoidCallback? alSalir;

  @override
  State<ShellPiloto> createState() => _ShellPilotoState();
}

class _ShellPilotoState extends State<ShellPiloto> {
  int _indice = 0;
  late final ConectividadServicio _conectividad =
      widget.conectividad ?? ConectividadFalsa();

  void _verDrones() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).perfilProveedorDronLicencia,
            ),
          ),
          body: const DronesPantalla(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return NavegacionAdaptativaCampo(
      destinos: [
        DestinoCampo(
          icono: Icons.map_outlined,
          iconoActivo: Icons.map_rounded,
          etiqueta: t.navMapa,
        ),
        DestinoCampo(
          icono: Icons.handshake_outlined,
          iconoActivo: Icons.handshake_rounded,
          etiqueta: t.navOfertas,
        ),
        DestinoCampo(
          icono: Icons.flight_takeoff_outlined,
          iconoActivo: Icons.flight_takeoff_rounded,
          etiqueta: t.navServicios,
        ),
        DestinoCampo(
          icono: Icons.person_outline_rounded,
          iconoActivo: Icons.person_rounded,
          etiqueta: t.navPerfil,
          bajoBarraEstado: true,
        ),
      ],
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: ConBannerDeRed(
        servicio: _conectividad,
        child: switch (_indice) {
          0 => const MapaSolicitudesPantalla(),
          1 => MisOfertasPantalla(
            alIrAlMapa: () => setState(() => _indice = 0),
          ),
          2 => ServiciosLotePantalla(
            alIrAlMapa: () => setState(() => _indice = 0),
          ),
          _ => PerfilPantalla(onVerDrones: _verDrones, alSalir: widget.alSalir),
        },
      ),
    );
  }
}
