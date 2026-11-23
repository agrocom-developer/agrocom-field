import 'package:flutter/material.dart';

import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'di/dependencias_auxiliar.dart';
import 'mezcla/presentation/mezcla_pantalla.dart';
import 'servicio_asignado/presentation/servicio_auxiliar_pantalla.dart';

/// Superficie del marketplace del flavor auxiliar con datos ficticios
/// (`MODO_DEMO`, ADR 0010). Tema modo campo.
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

class ShellAuxiliar extends StatefulWidget {
  const ShellAuxiliar({super.key});

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
      icono: Icons.science_outlined,
      iconoActivo: Icons.science_rounded,
      etiqueta: 'Mezcla',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavegacionAdaptativaCampo(
      destinos: _destinos,
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: _indice == 0
          ? const ServicioAuxiliarPantalla()
          : const MezclaPantalla(),
    );
  }
}
