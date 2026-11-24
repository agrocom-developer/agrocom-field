import 'package:flutter/material.dart';

import '../nucleo/marketplace/proveedor/dron/presentation/drones_pantalla.dart';
import '../nucleo/marketplace/proveedor/ejecucion/presentation/servicios_lote_pantalla.dart';
import '../nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart';
import '../nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_pantalla.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/extras_perfil.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/perfil_pantalla.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'di/dependencias_piloto.dart';

/// Superficie del marketplace del flavor piloto con datos ficticios
/// (`MODO_DEMO`, ADR 0010). Tema modo campo (alto contraste, objetivos de
/// 56 px). La misma [ShellPiloto] la monta la app real (`AppPiloto`) con los
/// repositorios de red.
class AppPilotoDemo extends StatelessWidget {
  const AppPilotoDemo({required this.dependencias, super.key});

  final DependenciasPiloto dependencias;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom',
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(),
      // Los repositorios van por encima del `Navigator`: las rutas que se
      // apilan (detalle, seguimiento) los heredan.
      builder: (context, child) => dependencias.proveer(child: child!),
      home: const ShellPiloto(),
    );
  }
}

/// Navegación del piloto: el mapa de solicitudes abiertas, sus ofertas, el
/// servicio adjudicado, sus drones y el perfil.
class ShellPiloto extends StatefulWidget {
  const ShellPiloto({this.alSalir, super.key});

  /// Cierra la sesión. Solo existe en la app real: la demo no tiene sesión.
  final VoidCallback? alSalir;

  @override
  State<ShellPiloto> createState() => _ShellPilotoState();
}

class _ShellPilotoState extends State<ShellPiloto> {
  int _indice = 0;

  static const _destinos = [
    DestinoCampo(
      icono: Icons.map_outlined,
      iconoActivo: Icons.map_rounded,
      etiqueta: 'Mapa',
    ),
    DestinoCampo(
      icono: Icons.handshake_outlined,
      iconoActivo: Icons.handshake_rounded,
      etiqueta: 'Ofertas',
    ),
    DestinoCampo(
      icono: Icons.flight_takeoff_outlined,
      iconoActivo: Icons.flight_takeoff_rounded,
      etiqueta: 'Servicio',
    ),
    DestinoCampo(
      icono: Icons.flight_outlined,
      iconoActivo: Icons.flight_rounded,
      etiqueta: 'Drones',
    ),
    DestinoCampo(
      icono: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavegacionAdaptativaCampo(
      destinos: _destinos,
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: switch (_indice) {
        0 => const MapaSolicitudesPantalla(),
        1 => const MisOfertasPantalla(),
        2 => const ServiciosLotePantalla(),
        3 => const DronesPantalla(),
        _ => PerfilPantalla(
          extras: extrasDePerfil(
            context,
            conAvisos: true,
            alSalir: widget.alSalir,
          ),
        ),
      },
    );
  }
}
