import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/foto_perfil/presentation/foto_perfil_widgets.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/notificaciones/bandeja/presentation/bandeja_notificaciones_pantalla.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/ajustes/ajustes_pantalla.dart';
import '../../../nucleo/ui/ajustes/apariencia_pantalla.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../contactos/domain/contacto.dart';
import '../../contactos/domain/contactos_repositorio.dart';
import '../../contactos/presentation/contactos_pantalla.dart';
import '../../solicitar/domain/solicitud_repositorio.dart';
import '../domain/cuenta_repositorio.dart';

/// Perfil del cliente (pantalla 17): cabecera con su calificación, métricas y
/// accesos a Mis lotes, Contactos, Calificaciones y Ajustes. Cerrar sesión
/// vive en el menú de tres puntos y en Ajustes.
class CuentaPantalla extends StatefulWidget {
  const CuentaPantalla({this.alCerrarSesion, super.key});

  /// Acción de cerrar sesión; sin ella el botón no se muestra.
  final VoidCallback? alCerrarSesion;

  @override
  State<CuentaPantalla> createState() => _CuentaPantallaState();
}

class _CuentaPantallaState extends State<CuentaPantalla> {
  /// Cambia al reintentar para que la carga vuelva a empezar.
  int _intento = 0;

  VoidCallback? get alCerrarSesion => widget.alCerrarSesion;

  /// El repositorio de contactos existe solo si la app lo provee.
  bool get conContactos {
    try {
      context.read<ContactosRepositorio>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  static String _iniciales(String nombre) => nombre
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  static Future<_Datos> _cargar(
    CuentaRepositorio cuentas,
    CalificacionRepositorio calificaciones,
    SolicitudRepositorio solicitudes,
  ) async {
    final (cuenta, resumen, lotes) = await (
      cuentas.cuenta(),
      calificaciones.recibidas(),
      solicitudes.lotesDelCliente(),
    ).wait;
    return _Datos(cuenta, resumen, lotes);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return FuturoEstable<_Datos>(
      key: ValueKey(_intento),
      crear: () => _cargar(
        context.read<CuentaRepositorio>(),
        context.read<CalificacionRepositorio>(),
        context.read<SolicitudRepositorio>(),
      ),
      builder: (context, snap) {
        if (snap.hasError) {
          return EstadoErrorMarketplace(
            titulo: t.perfilErrorCargaTitulo,
            detalle: t.perfilErrorCargaDetalle,
            onReintentar: () => setState(() => _intento++),
          );
        }
        final d = snap.data;
        if (d == null) {
          return const Padding(
            padding: EdgeInsets.all(EspaciadoCampo.l),
            child: EsqueletoCampo(alto: 160),
          );
        }
        final cuenta = d.cuenta;
        final resumen = d.resumen;
        final promedio = resumen.promedio
            .toStringAsFixed(1)
            .replaceAll('.', ',');
        final hectareas = d.lotes.fold<Decimal>(
          Decimal.zero,
          (suma, lote) => suma + lote.hectareas,
        );
        void abrir(Widget pantalla) => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => pantalla));
        void abrirCalificaciones() =>
            abrir(CalificacionesPantalla(resumen: resumen));
        void abrirAjustes() => abrir(AjustesPantalla(alSalir: alCerrarSesion));
        return ListView(
          children: [
            FotoPerfilProveedor(
              child: Column(
                children: [
                  CabeceraPerfilCampo(
                    accion: MenuPerfilCampo(
                      alAjustes: abrirAjustes,
                      alApariencia: () => abrir(const AparienciaPantalla()),
                      alSalir: alCerrarSesion,
                    ),
                    avatar: AvatarFotoPerfil(
                      iniciales: _iniciales(cuenta.nombre),
                      nombre: cuenta.nombre,
                      tamano: 88,
                    ),
                    nombre: cuenta.nombre,
                    detalle: cuenta.empresa.isEmpty
                        ? t.perfilClienteRol
                        : '${t.perfilClienteRol} · ${cuenta.empresa}',
                    extra: EstrellasPerfilCampo(
                      key: const Key('perfil-estrellas'),
                      valor: resumen.total == 0 ? 5 : resumen.promedio,
                      total: resumen.total,
                      onTap: abrirCalificaciones,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
                    child: AccionesFotoPerfil(compacta: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: EntradaCampo.escalonar([
                  Semantics(
                    header: true,
                    child: Text(t.perfilCliMetricas, style: texto.titleLarge),
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                  CifrasPerfilCampo(
                    cifras: [
                      (
                        valor: '${d.lotes.length}',
                        etiqueta: t.perfilClienteEstadLotes,
                      ),
                      (
                        valor: '${cuenta.serviciosTotales}',
                        etiqueta: t.perfilClienteEstadServicios,
                      ),
                      (
                        valor: FormatoMarketplace.hectareasNumero(hectareas),
                        etiqueta: t.perfilCli2EstadHectareas,
                      ),
                    ],
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  Semantics(
                    header: true,
                    child: Text(t.perfilR3MiCuenta, style: texto.titleLarge),
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                  if (cuenta.empresa.isNotEmpty && conContactos) ...[
                    _FilaContactos(),
                    const SizedBox(height: EspaciadoCampo.m),
                  ],
                  FilaAccionCampo(
                    clave: const Key('perfil-calificaciones'),
                    icono: Icons.star_rounded,
                    titulo: t.perfilUxCalificacionesTitulo,
                    detalle: resumen.total == 0
                        ? t.perfilCliCalificacionesSinDatos
                        : t.perfilCliCalificacionesDetalle(
                            promedio,
                            resumen.total,
                          ),
                    alToque: abrirCalificaciones,
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                  FilaAccionCampo(
                    clave: const Key('perfil-notificaciones'),
                    icono: Icons.notifications_none_rounded,
                    titulo: t.perfilCli2Notificaciones,
                    detalle: t.perfilCli2NotificacionesDetalle,
                    alToque: () => abrir(const BandejaNotificacionesPantalla()),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// «Contactos de referencia · N personas»: abre la pantalla de contactos.
class _FilaContactos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FuturoEstable<List<ContactoCliente>>(
      crear: () => context.read<ContactosRepositorio>().listar(),
      builder: (context, snap) => FilaAccionCampo(
        clave: const Key('perfil-contactos'),
        icono: Icons.groups_outlined,
        titulo: t.contactosPerfilFila,
        detalle: snap.data == null
            ? null
            : t.contactosPerfilDetalle(snap.data!.length),
        alToque: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ContactosPantalla()),
        ),
      ),
    );
  }
}

class _Datos {
  const _Datos(this.cuenta, this.resumen, this.lotes);

  final CuentaCliente cuenta;
  final ResumenCalificaciones resumen;
  final List<Lote> lotes;
}
