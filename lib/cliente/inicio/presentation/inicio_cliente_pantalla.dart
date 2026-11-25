import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/aparicion_marketplace.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/calificar_pantalla.dart';
import '../../ofertas/presentation/ofertas_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/presentation/solicitud_detalle_pantalla.dart';
import '../../solicitudes/presentation/tarjeta_solicitud.dart';
import '../domain/inicio_cliente_repositorio.dart';
import 'inicio_cliente_cubit.dart';
import '../../../l10n/app_localizations.dart';

/// Inicio del cliente: la acción principal (el botón flotante «Publicar
/// lote»), la solicitud activa, los avisos del día y el historial reciente. Lee el
/// `InicioClienteCubit` que provee la navegación principal.
///
/// En teléfono es una columna; desde 600 px de ancho (iPad) pasa a dos
/// columnas: lo que pide acción a la izquierda, lo informativo a la derecha.
class InicioClientePantalla extends StatelessWidget {
  const InicioClientePantalla({
    required this.alSolicitar,
    this.alVerServicios,
    super.key,
  });

  final VoidCallback alSolicitar;

  /// Abre la lista completa de servicios (pestaña Servicios).
  final VoidCallback? alVerServicios;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InicioClienteCubit>();
    return BlocBuilder<InicioClienteCubit, InicioClienteEstado>(
      builder: (context, estado) {
        final cuerpo = switch (estado) {
          InicioClienteCargando() => const _Cargando(key: ValueKey('carga')),
          InicioClienteFallido(:final sinConexion) => _Fallo(
            key: const ValueKey('fallo'),
            sinConexion: sinConexion,
            alReintentar: cubit.cargar,
          ),
          InicioClienteListo(:final resumen) => Stack(
            key: const ValueKey('listo'),
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  color: context.paleta.acentoTexto,
                  backgroundColor: context.paleta.superficieElevada,
                  onRefresh: cubit.actualizar,
                  child: _Contenido(
                    resumen: resumen,
                    alSolicitar: alSolicitar,
                    alVerServicios: alVerServicios,
                  ),
                ),
              ),
              Positioned(
                right: EspaciadoCampo.l,
                bottom: EspaciadoCampo.l,
                child: _BotonPublicar(alSolicitar: alSolicitar),
              ),
            ],
          ),
        };
        // El esqueleto se funde con el contenido: el cambio no es un salto.
        return AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          switchOutCurve: MovimientoCampo.salida,
          layoutBuilder: (actual, anteriores) =>
              Stack(fit: StackFit.expand, children: [...anteriores, ?actual]),
          child: cuerpo,
        );
      },
    );
  }
}

/// Ancho desde el que el inicio se parte en dos columnas.
const double _anchoDosColumnas = 600;

EdgeInsets _margen(double ancho) => EdgeInsets.fromLTRB(
  EspaciadoCampo.margenLateral(ancho),
  EspaciadoCampo.xl,
  EspaciadoCampo.margenLateral(ancho),
  // Deja pasar el botón flotante «Publicar lote» al final del desplazamiento.
  EspaciadoCampo.xxxl + ObjetivoTactilCampo.guantes + EspaciadoCampo.xl,
);

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.resumen,
    required this.alSolicitar,
    required this.alVerServicios,
  });

  final ResumenInicio resumen;
  final VoidCallback alSolicitar;
  final VoidCallback? alVerServicios;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activo = resumen.solicitudActiva;

    final saludo = _Saludo(nombre: resumen.nombre, empresa: resumen.empresa);

    final bloqueActivo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activo == null)
          const _SinServicioActivo()
        else ...[
          TarjetaSolicitud(
            solicitud: activo,
            destacada: true,
            titulo: l10n.inicioSolicitudActiva,
            onTap: () => _abrirDetalle(context, activo),
            acciones: [
              if (activo.estado == EstadoSolicitud.conOfertas)
                BotonPrincipalMarketplace(
                  key: const Key('inicio-ver-ofertas'),
                  texto: l10n.inicioCompararOfertas,
                  onPressed: () => _verOfertas(context, activo),
                )
              else if (activo.estado.conPiloto)
                BotonPrincipalMarketplace(
                  key: const Key('inicio-ver-seguimiento'),
                  texto: l10n.inicioVerSeguimiento,
                  onPressed: () => _seguir(context, activo),
                ),
            ],
          ),
          if (resumen.otrosActivos > 0 && alVerServicios != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: alVerServicios,
                style: _estiloEnlace(context),
                child: Text(
                  resumen.otrosActivos == 1
                      ? l10n.inicioVerOtraSolicitudActiva
                      : l10n.inicioVerLasOtrasSolicitudes(resumen.otrosActivos),
                ),
              ),
            ),
        ],
      ],
    );

    final bloquePorCalificar = resumen.porCalificar.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Seccion(l10n.inicioPorCalificar),
              for (final s in resumen.porCalificar) ...[
                TarjetaSolicitud(
                  solicitud: s,
                  onTap: () => _abrirDetalle(context, s),
                  acciones: [
                    OutlinedButton.icon(
                      onPressed: () => abrirCalificar(context, s),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: Text(l10n.inicioCalificar),
                    ),
                  ],
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
            ],
          );

    // En dos columnas, el primer bloque de la derecha arranca a la altura
    // de la tarjeta de solicitar: su título no lleva margen superior.
    Widget? bloqueAvisos({bool primero = false}) => resumen.avisos.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Seccion(l10n.inicioAvisos, primera: primero),
              for (final a in resumen.avisos) ...[
                _TarjetaAviso(
                  key: ValueKey(a.id),
                  aviso: a,
                  alDescartar: () =>
                      context.read<InicioClienteCubit>().descartarAviso(a.id),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
            ],
          );

    Widget? bloqueRecientes({bool primero = false}) => resumen.recientes.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Seccion(
                l10n.inicioHistorialReciente,
                primera: primero,
                accion: alVerServicios == null ? null : l10n.inicioVerTodo,
                alAccionar: alVerServicios,
              ),
              _ListaRecientes(
                solicitudes: resumen.recientes,
                alAbrir: (s) => _abrirDetalle(context, s),
              ),
            ],
          );

    return LayoutBuilder(
      builder: (context, c) {
        Widget columna(List<Widget?> bloques, {int desde = 0}) {
          final visibles = bloques.whereType<Widget>().toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visibles.length; i++)
                AparicionMarketplace(orden: desde + i, child: visibles[i]),
            ],
          );
        }

        final Widget cuerpo;
        if (c.maxWidth >= _anchoDosColumnas) {
          cuerpo = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AparicionMarketplace(child: saludo),
              const SizedBox(height: EspaciadoCampo.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: columna([
                      bloqueActivo,
                      bloquePorCalificar,
                    ], desde: 1),
                  ),
                  const SizedBox(width: EspaciadoCampo.xl),
                  Expanded(
                    flex: 5,
                    child: columna([
                      bloqueAvisos(primero: true),
                      bloqueRecientes(primero: resumen.avisos.isEmpty),
                    ], desde: 2),
                  ),
                ],
              ),
            ],
          );
        } else {
          cuerpo = columna([
            saludo,
            const SizedBox(height: EspaciadoCampo.xl),
            bloqueActivo,
            bloqueAvisos(),
            bloquePorCalificar,
            bloqueRecientes(),
          ]);
        }
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _margen(c.maxWidth),
          child: cuerpo,
        );
      },
    );
  }

  static ButtonStyle _estiloEnlace(BuildContext context) =>
      TextButton.styleFrom(
        minimumSize: const Size(
          ObjetivoTactilCampo.minimo,
          ObjetivoTactilCampo.minimo,
        ),
        foregroundColor: context.paleta.acentoTexto,
      );

  static void _abrirDetalle(BuildContext context, Solicitud s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudDetallePantalla(solicitudId: s.id),
      ),
    );
  }

  static void _verOfertas(BuildContext context, Solicitud s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfertasPantalla(solicitudId: s.id),
      ),
    );
  }

  static void _seguir(BuildContext context, Solicitud s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientoPantalla(solicitudId: s.id),
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo({required this.nombre, this.empresa});

  final String nombre;
  final String? empresa;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (empresa != null)
                Text(
                  empresa!,
                  style: TipografiaCampo.cuerpoSecundario.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  l10n.inicioHola(nombre),
                  style: TipografiaCampo.tituloPantalla.copyWith(
                    color: paleta.texto,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: EspaciadoCampo.m),
        AvatarFoto(
          iniciales: nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
          etiqueta: l10n.inicioPerfil,
          tamano: ObjetivoTactilCampo.guantes - EspaciadoCampo.s,
        ),
      ],
    );
  }
}

/// La acción principal del inicio: «Publicar lote», un botón flotante
/// grafito con el «+» en ámbar (la acción especial del sistema visual).
class _BotonPublicar extends StatelessWidget {
  const _BotonPublicar({required this.alSolicitar});

  final VoidCallback alSolicitar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return FloatingActionButton.extended(
      key: const Key('inicio-solicitar'),
      onPressed: alSolicitar,
      backgroundColor: paleta.grafito,
      foregroundColor: paleta.sobreGrafito,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
      ),
      icon: Icon(Icons.add_rounded, color: paleta.ambar),
      label: Text(
        l10n.inicioPublicarLote,
        style: TipografiaCampo.tituloSeccion.copyWith(
          color: paleta.sobreGrafito,
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(
    this.titulo, {
    this.accion,
    this.alAccionar,
    this.primera = false,
  });

  /// Sin margen superior: es lo primero de su columna.
  final bool primera;

  final String titulo;
  final String? accion;
  final VoidCallback? alAccionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: primera ? 0 : EspaciadoCampo.l,
        bottom: EspaciadoCampo.xs,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.m),
            child: Semantics(
              header: true,
              child: Text(
                titulo,
                style: TipografiaCampo.tituloSeccion.copyWith(
                  color: context.paleta.texto,
                ),
              ),
            ),
          ),
          if (accion != null)
            TextButton(
              onPressed: alAccionar,
              style: _Contenido._estiloEnlace(context),
              child: Text(accion!),
            ),
        ],
      ),
    );
  }
}

/// Vacío del servicio activo: orienta sin repetir el botón principal.
class _SinServicioActivo extends StatelessWidget {
  const _SinServicioActivo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return SuperficieMarketplace(
      child: Row(
        children: [
          Icon(Icons.grass_rounded, color: paleta.textoSecundario, size: 28),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inicioTienesSolicitudesCurso,
                  style: TipografiaCampo.tituloTarjeta.copyWith(
                    color: paleta.texto,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  l10n.inicioTocaPublicarLoteMarca,
                  style: TipografiaCampo.cuerpoSecundario.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({
    required this.aviso,
    required this.alDescartar,
    super.key,
  });

  final AvisoInicio aviso;
  final VoidCallback alDescartar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final (rol, icono) = switch (aviso.tono) {
      TonoAvisoInicio.info => (paleta.info, Icons.wb_sunny_outlined),
      TonoAvisoInicio.alerta => (paleta.alerta, Icons.schedule_rounded),
    };
    // Par tonal del rol: fondo y texto con contraste medido, sin alpha.
    final (:fondo, texto: color) = paleta.contenedorDe(rol);
    return Container(
      padding: const EdgeInsets.only(
        left: EspaciadoCampo.l,
        top: EspaciadoCampo.xs,
        bottom: EspaciadoCampo.m,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: EspaciadoCampo.m),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: EspaciadoCampo.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aviso.titulo,
                    style: TipografiaCampo.tituloTarjeta.copyWith(color: color),
                  ),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    aviso.detalle,
                    style: TipografiaCampo.cuerpoSecundario.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.inicioDescartarAviso,
            onPressed: () {
              HapticaCampo.seleccion();
              alDescartar();
            },
            icon: Icon(Icons.close_rounded, color: color),
          ),
        ],
      ),
    );
  }
}

/// Historial reciente: filas compactas dentro de una sola superficie.
class _ListaRecientes extends StatelessWidget {
  const _ListaRecientes({required this.solicitudes, required this.alAbrir});

  final List<Solicitud> solicitudes;
  final ValueChanged<Solicitud> alAbrir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return SuperficieMarketplace(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < solicitudes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: paleta.borde),
            InkWell(
              onTap: () => alAbrir(solicitudes[i]),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ObjetivoTactilCampo.guantes,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspaciadoCampo.l,
                    vertical: EspaciadoCampo.m,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              solicitudes[i].lote.nombre,
                              style: TipografiaCampo.tituloTarjeta.copyWith(
                                color: paleta.texto,
                              ),
                            ),
                            const SizedBox(height: EspaciadoCampo.xs),
                            Text(
                              '${FormatoMarketplace.fechaCorta(solicitudes[i].ventanaDesde)} · '
                              '${FormatoMarketplace.hectareas(solicitudes[i].hectareas)}',
                              style: TipografiaCampo.datoMono.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (solicitudes[i].puntajeDelCliente != null)
                        Semantics(
                          label: l10n.inicioCalificasteCon(
                            solicitudes[i].puntajeDelCliente!,
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: paleta.ambar,
                                ),
                                const SizedBox(width: EspaciadoCampo.xs),
                                Text(
                                  '${solicitudes[i].puntajeDelCliente}',
                                  style: TipografiaCampo.cifraUnidad.copyWith(
                                    color: paleta.texto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: EspaciadoCampo.s),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: paleta.textoSecundario,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Esqueleto con la forma del inicio: saludo, tarjeta de la solicitud
/// activa, sección y fila del historial.
class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: _margen(c.maxWidth),
        child: const EsqueletoListaCampo(
          separacion: EspaciadoCampo.l,
          bloques: [
            BloqueEsqueleto(alto: 32, ancho: 180),
            BloqueEsqueleto(alto: 18, ancho: 220),
            BloqueEsqueleto(alto: 240, radio: RadioCampo.tarjeta),
            BloqueEsqueleto(alto: 22, ancho: 110),
            BloqueEsqueleto(alto: 88, radio: RadioCampo.tarjetaCompacta),
          ],
        ),
      ),
    );
  }
}

/// Error al cargar el inicio, con salida: reintentar.
class _Fallo extends StatelessWidget {
  const _Fallo({
    required this.sinConexion,
    required this.alReintentar,
    super.key,
  });

  final bool sinConexion;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EstadoVacioMarketplace(
              icono: sinConexion
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              titulo: sinConexion
                  ? l10n.inicioSinConexion
                  : l10n.inicioPudimosCargarInicio,
              detalle: sinConexion
                  ? l10n.inicioRevisaSenalIntentaNuevo
                  : l10n.inicioIntentaNuevoMomento,
            ),
            OutlinedButton.icon(
              key: const Key('inicio-reintentar'),
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.inicioReintentar),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
          ],
        ),
      ),
    );
  }
}
