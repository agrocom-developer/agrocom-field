import 'package:flutter/material.dart';

import '../nucleo/marketplace/proveedor/dron/presentation/drones_pantalla.dart';
import '../nucleo/marketplace/proveedor/ejecucion/presentation/servicios_lote_pantalla.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/extras_perfil.dart';
import '../nucleo/marketplace/proveedor/perfil/presentation/perfil_pantalla.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'di/dependencias_auxiliar.dart';

/// Superficie del marketplace del flavor auxiliar con datos ficticios
/// (`MODO_DEMO`, ADR 0010). Tema modo campo. La misma [ShellAuxiliar] la
/// monta la app real (`AppAuxiliar`) con los repositorios de red.
class AppAuxiliarDemo extends StatelessWidget {
  const AppAuxiliarDemo({required this.dependencias, super.key});

  final DependenciasAuxiliar dependencias;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom',
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(),
      // Los repositorios van por encima del `Navigator`: las rutas que se
      // apilan (detalle, seguimiento) los heredan.
      builder: (context, child) => dependencias.proveer(child: child!),
      home: const ShellAuxiliar(),
    );
  }
}

/// Navegación del auxiliar: el servicio adjudicado de su equipo y el perfil.
class ShellAuxiliar extends StatefulWidget {
  const ShellAuxiliar({this.alSalir, super.key});

  /// Cierra la sesión. Solo existe en la app real.
  final VoidCallback? alSalir;

  @override
  State<ShellAuxiliar> createState() => _ShellAuxiliarState();
}

class _ShellAuxiliarState extends State<ShellAuxiliar> {
  int _indice = 0;

  static const _destinos = [
    DestinoCampo(
      icono: Icons.inventory_2_outlined,
      iconoActivo: Icons.inventory_2_rounded,
      etiqueta: 'Servicio',
    ),
    DestinoCampo(
      icono: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: 'Perfil',
    ),
  ];

  void _verDrones() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: const SafeArea(child: DronesPantalla()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavegacionAdaptativaCampo(
      destinos: _destinos,
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: switch (_indice) {
        0 => const ServiciosLotePantalla(),
        _ => PerfilPantalla(
          onVerDrones: _verDrones,
          extras: extrasDePerfil(
            context,
            conAvisos: false,
            alSalir: widget.alSalir,
          ),
        ),
      },
    );
  }
}
