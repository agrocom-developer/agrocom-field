import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../l10n/app_localizations.dart';
import '../nucleo/ui/paleta_campo.dart';
import '../nucleo/ui/componentes/componentes_campo.dart';
import '../nucleo/ui/tema_visual/tema_visual_app.dart';
import '../nucleo/ui/tema_visual/tema_visual_cubit.dart';
import '../nucleo/ui/tokens_campo.dart';
import 'acceso/presentation/arranque_cubit.dart';
import 'acceso/presentation/puerta_acceso_cliente.dart';
import 'di/dependencias_cliente.dart';
import 'inicio/domain/inicio_cliente_repositorio.dart';
import 'inicio/presentation/inicio_cliente_cubit.dart';
import 'inicio/presentation/inicio_cliente_pantalla.dart';
import 'solicitar/presentation/solicitar_pantalla.dart';
import 'solicitudes/domain/solicitud.dart';
import 'solicitudes/presentation/historial_pantalla.dart';
import 'solicitudes/presentation/solicitud_detalle_pantalla.dart';
import 'cuenta/presentation/cuenta_pantalla.dart';
import 'lotes/presentation/lotes_pantalla.dart';

/// App del flavor cliente. Sigue al sistema (claro u oscuro) mientras la
/// persona no elija otro tema en su perfil (sistema visual, §2); la elección
/// se guarda en [almacenTema].
class AppCliente extends StatelessWidget {
  const AppCliente({required this.dependencias, this.almacenTema, super.key});

  final DependenciasCliente dependencias;

  /// Dónde se guarda el tema elegido; por defecto `shared_preferences`.
  final AlmacenTemaVisual? almacenTema;

  @override
  Widget build(BuildContext context) {
    return TemaVisualApp(
      predeterminado: ModoVisualCampo.claro,
      almacen: almacenTema,
      construir: (context, tema) => MaterialApp(
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
        // La puerta decide entre splash, presentación, acceso y navegación.
        home: PuertaAccesoCliente(
          notaAcceso: dependencias.notaAcceso,
          sesionExpirada: dependencias.sesionExpirada,
          dentro: (context) => ShellCliente(
            alCerrarSesion: context.read<ArranqueCubit>().cerrarSesion,
          ),
        ),
      ),
    );
  }
}

/// Navegación raíz del cliente: Inicio, Lotes, Servicios y Perfil. Barra
/// inferior en teléfono y riel lateral en iPad (`NavegacionAdaptativaCampo`).
/// «Publicar lote» no es un destino: es la acción principal del inicio y abre
/// el flujo sobre la navegación.
class ShellCliente extends StatefulWidget {
  const ShellCliente({this.alCerrarSesion, super.key});

  /// Cierra la sesión desde el perfil. Sin él, el perfil no ofrece la
  /// acción.
  final VoidCallback? alCerrarSesion;

  @override
  State<ShellCliente> createState() => _ShellClienteState();
}

class _ShellClienteState extends State<ShellCliente> {
  int _indice = 0;

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

  /// Abre el flujo de publicación sobre la navegación; al publicar, lo cierra
  /// y abre el detalle de la solicitud, desde donde se ven las ofertas.
  Future<void> _publicarLote() async {
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final textos = AppLocalizations.of(context);
    final publicada = await navegador.push<Solicitud>(
      MaterialPageRoute<Solicitud>(
        fullscreenDialog: true,
        builder: (_) => const _PublicarLoteRuta(),
      ),
    );
    if (publicada == null || !mounted) return;
    setState(() => _indice = 0);
    mensajes.showSnackBar(SnackBar(content: Text(textos.solicitudPublicada)));
    unawaited(
      navegador.push(
        MaterialPageRoute<void>(
          builder: (_) => SolicitudDetallePantalla(solicitudId: publicada.id),
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
          icono: Icons.home_outlined,
          iconoActivo: Icons.home_rounded,
          etiqueta: t.navInicio,
        ),
        DestinoCampo(
          icono: Icons.crop_square_rounded,
          iconoActivo: Icons.crop_square_rounded,
          etiqueta: t.navLotes,
        ),
        DestinoCampo(
          icono: Icons.list_alt_outlined,
          iconoActivo: Icons.list_alt_rounded,
          etiqueta: t.navServicios,
        ),
        DestinoCampo(
          icono: Icons.person_outline_rounded,
          iconoActivo: Icons.person_rounded,
          etiqueta: t.navPerfil,
        ),
      ],
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
      cuerpo: switch (_indice) {
        0 => BlocProvider.value(
          value: _inicio,
          child: InicioClientePantalla(
            alSolicitar: _publicarLote,
            alVerServicios: () => setState(() => _indice = 2),
          ),
        ),
        1 => LotesPantalla(alPublicar: _publicarLote),
        2 => HistorialPantalla(alPublicar: _publicarLote),
        _ => CuentaPantalla(
          alCerrarSesion: widget.alCerrarSesion,
          alPublicar: _publicarLote,
        ),
      },
    );
  }
}

/// El flujo de publicar un lote como pantalla propia, con salida a la
/// izquierda. Al terminar devuelve la solicitud publicada.
class _PublicarLoteRuta extends StatelessWidget {
  const _PublicarLoteRuta();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      // El título «Publicar lote» lo pone el propio flujo; aquí solo la
      // salida.
      appBar: AppBar(
        toolbarHeight: ObjetivoTactilCampo.minimo,
        leading: IconButton(
          tooltip: t.publicarLoteCerrar,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SolicitarPantalla(
          alSolicitado: (solicitud) => Navigator.of(context).pop(solicitud),
        ),
      ),
    );
  }
}
