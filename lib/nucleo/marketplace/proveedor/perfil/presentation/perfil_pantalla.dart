import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../../ui/ajustes/ajustes_pantalla.dart';
import '../../../../ui/ajustes/apariencia_pantalla.dart';
import '../../../foto_perfil/presentation/foto_perfil_widgets.dart';
import '../../../ui/marketplace_ui.dart';
import '../../negociacion/presentation/avisos_pantalla.dart';
import '../domain/perfil_repositorio.dart';
import '../../../../notificaciones/bandeja/presentation/bandeja_notificaciones_pantalla.dart';
import 'actividad_pantalla.dart';
import 'documentos_pantalla.dart';
import 'perfil_cubit.dart';
import 'perfil_estado.dart';

/// Perfil del proveedor: quién es y si está habilitado para operar, sus
/// métricas, documentos, equipo y lo que los clientes dijeron de su trabajo.
/// Es el mismo en los flavors `piloto`.
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({
    this.reloj = DateTime.now,
    this.onVerDrones,
    this.conAvisos = true,
    this.alSalir,
    super.key,
  });

  final DateTime Function() reloj;

  /// Abre «Mis drones». Sin él la fila no se muestra (el flavor ya los
  /// tiene como destino de la navegación).
  final VoidCallback? onVerDrones;

  /// Muestra la fila y la entrada de menú de notificaciones (solo con
  /// negociación).
  final bool conAvisos;

  /// Cierra la sesión (menú de tres puntos y Ajustes). Sin él no se ofrece.
  final VoidCallback? alSalir;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PerfilCubit(context.read<PerfilRepositorio>())..cargar(),
      child: PerfilVista(
        reloj: reloj,
        onVerDrones: onVerDrones,
        conAvisos: conAvisos,
        alSalir: alSalir,
      ),
    );
  }
}

/// El perfil sobre un [PerfilCubit] ya provisto.
class PerfilVista extends StatelessWidget {
  const PerfilVista({
    this.reloj = DateTime.now,
    this.onVerDrones,
    this.conAvisos = true,
    this.alSalir,
    super.key,
  });

  final DateTime Function() reloj;
  final VoidCallback? onVerDrones;
  final bool conAvisos;
  final VoidCallback? alSalir;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilCubit, PerfilEstado>(
      builder: (context, estado) {
        return AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          switchOutCurve: MovimientoCampo.salida,
          child: switch (estado) {
            PerfilCargando() => const _Cargando(key: ValueKey('cargando')),
            PerfilError() => EstadoErrorMarketplace(
              key: const ValueKey('error'),
              titulo: AppLocalizations.of(context).perfilProveedorErrorTitulo,
              detalle: AppLocalizations.of(context).perfilProveedorErrorDetalle,
              onReintentar: context.read<PerfilCubit>().cargar,
            ),
            PerfilListo() => _Contenido(
              key: const ValueKey('listo'),
              datos: estado,
              ahora: reloj(),
              onVerDrones: onVerDrones,
              conAvisos: conAvisos,
              alSalir: alSalir,
            ),
          },
        );
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        Row(
          children: [
            EsqueletoCampo(ancho: 64, alto: 64, radio: 32),
            SizedBox(width: EspaciadoCampo.l),
            Expanded(child: EsqueletoCampo(alto: 56)),
          ],
        ),
        SizedBox(height: EspaciadoCampo.xl),
        EsqueletoCampo(alto: 72, radio: 18),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 160, radio: 18),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 200, radio: 18),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.datos,
    required this.ahora,
    required this.onVerDrones,
    required this.conAvisos,
    required this.alSalir,
    super.key,
  });

  final PerfilListo datos;
  final DateTime ahora;
  final VoidCallback? onVerDrones;
  final bool conAvisos;
  final VoidCallback? alSalir;

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final p = datos.proveedor;
    final t = AppLocalizations.of(context);
    final sinCalificaciones = datos.calificaciones.total == 0;
    final promedio = datos.calificaciones.promedio
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    void verCalificaciones() => _abrir(
      context,
      CalificacionesPantalla(resumen: datos.calificaciones, reloj: () => ahora),
    );
    void verAvisos() => _abrir(context, const AvisosPantalla());
    void verCobertura() => _abrir(
      context,
      ActividadPantalla(meses: datos.hectareasPorMes, zonas: p.zonas),
    );
    // Notificaciones también vive en Ajustes, con el estilo de esa pantalla.
    void verAjustes() => _abrir(
      context,
      AjustesPantalla(
        alSalir: alSalir,
        filas: [
          if (conAvisos)
            FilaAjusteCampo(
              clave: const Key('ajustes-avisos'),
              icono: Icons.notifications_active_outlined,
              titulo: t.perfilProveedorAvisos,
              detalle: t.perfilPil2AvisosConfigDetalle,
              alToque: verAvisos,
            ),
        ],
      ),
    );
    return FotoPerfilProveedor(
      urlInicial: p.fotoUrl,
      child: ListView(
        children: [
          CabeceraPerfilCampo(
            accion: MenuPerfilCampo(
              alAjustes: verAjustes,
              alApariencia: () => _abrir(context, const AparienciaPantalla()),
              alSalir: alSalir,
              extras: [
                if (conAvisos)
                  (
                    icono: Icons.notifications_active_outlined,
                    etiqueta: t.perfilProveedorAvisos,
                    alToque: verAvisos,
                  ),
                (
                  icono: Icons.map_outlined,
                  etiqueta: t.perfilPil2Cobertura,
                  alToque: verCobertura,
                ),
              ],
            ),
            avatar: AvatarFotoPerfil(
              iniciales: p.iniciales,
              nombre: p.nombre,
              tamano: 88,
            ),
            nombre: p.nombre,
            detalle: '${t.perfilProveedorRolPiloto} · ${p.tipo.etiqueta}',
            // Sin calificaciones el piloto empieza con 5 estrellas.
            extra: EstrellasPerfilCampo(
              valor: sinCalificaciones ? 5 : p.calificacion,
              total: datos.calificaciones.total,
              onTap: verCalificaciones,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: EntradaCampo.escalonar([
                const AccionesFotoPerfil(compacta: true),
                _Aprobacion(proveedor: p),
                _Titulo(t.perfilProveedorMetricas),
                _Metricas(metricas: datos.metricas),
                const SizedBox(height: EspaciadoCampo.l),
                if (conAvisos) ...[
                  FilaAccionCampo(
                    clave: const Key('perfil-avisos'),
                    icono: Icons.notifications_active_outlined,
                    titulo: t.perfilProveedorAvisos,
                    detalle: t.perfilPil2BandejaDetalle,
                    alToque: () =>
                        _abrir(context, const BandejaNotificacionesPantalla()),
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                ],
                if (onVerDrones != null) ...[
                  FilaAccionCampo(
                    clave: const Key('perfil-ver-drones'),
                    icono: Icons.flight_rounded,
                    titulo: t.perfilPilMisDrones,
                    detalle: t.perfilPil2DronesDetalle(
                      p.drones.length == 1
                          ? t.perfilProveedorDronesUno
                          : t.perfilProveedorDronesVarios(p.drones.length),
                    ),
                    alToque: onVerDrones!,
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                ],
                FilaAccionCampo(
                  clave: const Key('perfil-documentos'),
                  icono: Icons.description_outlined,
                  titulo: t.perfilProveedorDocumentos,
                  detalle: t.perfilPilDocumentosDetalle,
                  alToque: () =>
                      _abrir(context, DocumentosPantalla(proveedor: p)),
                ),
                const SizedBox(height: EspaciadoCampo.m),
                FilaAccionCampo(
                  clave: const Key('perfil-calificaciones'),
                  icono: Icons.star_outline_rounded,
                  titulo: t.perfilPilCalificaciones,
                  detalle: sinCalificaciones
                      ? t.perfilProveedorSinCalificaciones
                      : t.perfilPilCalificacionesDetalle(
                          promedio,
                          datos.calificaciones.total,
                        ),
                  alToque: verCalificaciones,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: EspaciadoCampo.l,
        bottom: EspaciadoCampo.m,
      ),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

/// Estado de aprobación del proveedor, con lo que significa para operar.
class _Aprobacion extends StatelessWidget {
  const _Aprobacion({required this.proveedor});

  final Proveedor proveedor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final (tono, icono, detalle) = switch (proveedor.aprobacion) {
      EstadoAprobacion.aprobado => (
        TonoEstado.exito,
        Icons.verified_rounded,
        l10n.proveedorPerfilEstasHabilitadoParaRecibir,
      ),
      EstadoAprobacion.pendiente => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
        l10n.proveedorPerfilAdministradorEstaRevisandoTus,
      ),
      EstadoAprobacion.suspendido => (
        TonoEstado.alerta,
        Icons.pause_circle_outline_rounded,
        l10n.proveedorPerfilRecibisOfertasMientrasDure,
      ),
      EstadoAprobacion.rechazado => (
        TonoEstado.error,
        Icons.cancel_outlined,
        l10n.proveedorPerfilSolicitudAproboPodesCorregir,
      ),
    };
    final motivo = proveedor.motivoAprobacion;
    // Aprobado no necesita explicación: solo el chip, centrado.
    if (proveedor.aprobacion == EstadoAprobacion.aprobado) {
      return Center(
        key: const Key('perfil-aprobacion'),
        child: ChipEstadoMarketplace(
          etiqueta: proveedor.aprobacion.etiqueta,
          tono: tono,
          icono: icono,
        ),
      );
    }
    return SuperficieMarketplace(
      key: const Key('perfil-aprobacion'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipEstadoMarketplace(
            etiqueta: proveedor.aprobacion.etiqueta,
            tono: tono,
            icono: icono,
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(detalle, style: texto.bodyLarge),
          if (motivo != null && !proveedor.aprobacion.habilitado) ...[
            const SizedBox(height: EspaciadoCampo.xs),
            Text(l10n.proveedorPerfilMotivo(motivo), style: texto.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.metricas});

  final MetricasProveedor metricas;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CifrasPerfilCampo(
      cifras: [
        (
          valor: '${metricas.serviciosCompletados}',
          etiqueta: l10n.proveedorPerfilServicios,
        ),
        (
          valor: FormatoMarketplace.numero(
            metricas.hectareasAtendidas,
            decimales: 0,
          ),
          etiqueta: l10n.proveedorPerfilHectareas,
        ),
        (
          valor: '${metricas.tasaCancelacion} %',
          etiqueta: l10n.proveedorPerfilCancelacion,
        ),
      ],
    );
  }
}
