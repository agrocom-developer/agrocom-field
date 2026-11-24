import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../nucleo/marketplace/dominio/dominio.dart';
import '../nucleo/ui/paleta_campo.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_campo.dart';
import 'acceso/presentation/arranque_cubit.dart';
import 'acceso/presentation/puerta_acceso_cliente.dart';
import 'di/dependencias_cliente.dart';
import 'inicio/domain/inicio_cliente_repositorio.dart';
import 'inicio/presentation/inicio_cliente_cubit.dart';
import 'inicio/presentation/inicio_cliente_pantalla.dart';
import 'solicitar/presentation/buscando_proveedor_pantalla.dart';
import 'solicitar/presentation/solicitar_pantalla.dart';
import 'cuenta/presentation/cuenta_pantalla.dart';
import 'servicios/presentation/historial_pantalla.dart';
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
      // La puerta decide entre splash, presentación, acceso y navegación.
      home: PuertaAccesoCliente(
        notaAcceso: dependencias.notaAcceso,
        sesionExpirada: dependencias.sesionExpirada,
        dentro: (context) => ShellCliente(
          alCerrarSesion: context.read<ArranqueCubit>().cerrarSesion,
        ),
      ),
    );
  }
}

/// Navegación raíz del cliente: Inicio, Solicitar, Servicios y Cuenta. Barra
/// inferior en teléfono y riel lateral en iPad (`NavegacionAdaptativaCampo`).
class ShellCliente extends StatefulWidget {
  const ShellCliente({this.alCerrarSesion, super.key});

  /// Cierra la sesión desde la pestaña Cuenta. Sin él, la cuenta no ofrece
  /// la acción.
  final VoidCallback? alCerrarSesion;

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

  // El cubit del inicio vive con la navegación: volver a la pestaña Inicio
  // no repite la carga.
  late final InicioClienteCubit _inicio = InicioClienteCubit(
    context.read<InicioClienteRepositorio>(),
  )..cargar();

  @override
  void dispose() {
    _inicio.close();
    super.dispose();
  }

  /// La solicitud ya está creada: se muestra la búsqueda de proveedor y,
  /// desde ahí, el detalle del servicio. Debajo queda el inicio.
  void _alSolicitado(Servicio servicio) {
    setState(() => _indice = 0);
    final navegador = Navigator.of(context);
    navegador.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BuscandoProveedorPantalla(
          servicio: servicio,
          alVerServicio: () => navegador.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ServicioDetallePantalla(servicioId: servicio.id),
            ),
          ),
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
      // Solicitar divide la pantalla en mapa y formulario en iPad.
      anchoCompleto: _indice == 1,
      cuerpo: switch (_indice) {
        0 => BlocProvider.value(
          value: _inicio,
          child: InicioClientePantalla(
            alSolicitar: () => setState(() => _indice = 1),
            alVerServicios: () => setState(() => _indice = 2),
          ),
        ),
        1 => SolicitarPantalla(alSolicitado: _alSolicitado),
        2 => const HistorialPantalla(),
        _ => CuentaPantalla(alCerrarSesion: widget.alCerrarSesion),
      },
    );
  }
}
