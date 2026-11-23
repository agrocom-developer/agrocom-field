import 'package:flutter/material.dart';

import '../nucleo/ui/paleta_campo.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'di/dependencias_cliente.dart';
import 'solicitar/presentation/solicitar_pantalla.dart';
import 'cuenta/presentation/cuenta_pantalla.dart';
import 'servicios/presentation/historial_pantalla.dart';
import 'servicios/presentation/inicio_cliente_pantalla.dart';
import 'servicios/presentation/servicio_detalle_pantalla.dart';

/// App del flavor cliente. Tema claro por defecto y oscuro según el sistema
/// (sistema visual, §2); el modo campo es solo de piloto y auxiliar.
class AppCliente extends StatelessWidget {
  const AppCliente({required this.dependencias, super.key});

  final DependenciasCliente dependencias;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom',
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
      darkTheme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.oscuro),
      // Los repositorios van por encima del `Navigator`: las rutas que se
      // apilan (detalle, seguimiento) los heredan.
      builder: (context, child) => dependencias.proveer(child: child!),
      home: const ShellCliente(),
    );
  }
}

/// Navegación raíz del cliente: Inicio, Solicitar, Servicios y Cuenta. Barra
/// inferior en teléfono y riel lateral en iPad (`NavegacionAdaptativaCampo`).
class ShellCliente extends StatefulWidget {
  const ShellCliente({super.key});

  @override
  State<ShellCliente> createState() => _ShellClienteState();
}

class _ShellClienteState extends State<ShellCliente> {
  int _indice = 0;

  static const _destinos = [
    DestinoCampo(
      icono: Icons.home_outlined,
      iconoActivo: Icons.home_rounded,
      etiqueta: 'Inicio',
    ),
    DestinoCampo(
      icono: Icons.add_circle_outline_rounded,
      iconoActivo: Icons.add_circle_rounded,
      etiqueta: 'Solicitar',
    ),
    DestinoCampo(
      icono: Icons.list_alt_outlined,
      iconoActivo: Icons.list_alt_rounded,
      etiqueta: 'Servicios',
    ),
    DestinoCampo(
      icono: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: 'Cuenta',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavegacionAdaptativaCampo(
      destinos: _destinos,
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: switch (_indice) {
        0 => InicioClientePantalla(
          alSolicitar: () => setState(() => _indice = 1),
        ),
        1 => SolicitarPantalla(
          alSolicitado: (s) {
            setState(() => _indice = 0);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ServicioDetallePantalla(servicioId: s.id),
              ),
            );
          },
        ),
        2 => const HistorialPantalla(),
        _ => const CuentaPantalla(),
      },
    );
  }
}
