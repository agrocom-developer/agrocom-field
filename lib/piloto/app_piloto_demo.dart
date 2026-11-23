import 'package:flutter/material.dart';

import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'di/dependencias_piloto.dart';
import '../nucleo/marketplace/proveedor/dron/presentation/drones_pantalla.dart';
import '../nucleo/marketplace/proveedor/ofertas/presentation/ofertas_pantalla.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/perfil_pantalla.dart';
import 'servicio_asignado/presentation/servicio_asignado_pantalla.dart';

/// Superficie del marketplace del flavor piloto con datos ficticios
/// (`MODO_DEMO`, ADR 0010). Tema modo campo (alto contraste, objetivos de
/// 56 px). Cuando existan los repositorios reales (tareas 34 a 37), este
/// árbol se monta con ellos y deja de ser exclusivo de la demo.
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

class ShellPiloto extends StatefulWidget {
  const ShellPiloto({super.key});

  @override
  State<ShellPiloto> createState() => _ShellPilotoState();
}

class _ShellPilotoState extends State<ShellPiloto> {
  int _indice = 0;

  static const _destinos = [
    DestinoCampo(
      icono: Icons.notifications_none_rounded,
      iconoActivo: Icons.notifications_rounded,
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
        0 => const OfertasPantalla(),
        1 => const ServicioAsignadoPantalla(),
        2 => const DronesPantalla(),
        _ => const PerfilPantalla(),
      },
    );
  }
}
