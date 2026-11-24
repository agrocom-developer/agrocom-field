import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/aparicion_marketplace.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/hoja_calificar.dart';
import '../../ofertas/presentation/ofertas_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/presentation/solicitud_detalle_pantalla.dart';
import '../../solicitudes/presentation/tarjeta_solicitud.dart';
import '../domain/inicio_cliente_repositorio.dart';
import 'inicio_cliente_cubit.dart';

/// Inicio del cliente: la acción principal (publicar una solicitud), la
/// solicitud activa, los avisos del día y el historial reciente. Lee el
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
          InicioClienteListo(:final resumen) => RefreshIndicator(
            key: const ValueKey('listo'),
            color: context.paleta.acentoTexto,
            backgroundColor: context.paleta.superficieElevada,
            onRefresh: cubit.actualizar,
            child: _Contenido(
              resumen: resumen,
              alSolicitar: alSolicitar,
              alVerServicios: alVerServicios,
            ),
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
  EspaciadoCampo.xxl,
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
    final activo = resumen.solicitudActiva;

    final saludo = _Saludo(nombre: resumen.nombre, empresa: resumen.empresa);
    final solicitar = _TarjetaSolicitar(alSolicitar: alSolicitar);

    final bloqueActivo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Seccion('Solicitud activa'),
        if (activo == null)
          const _SinServicioActivo()
        else ...[
          TarjetaSolicitud(
            solicitud: activo,
            resaltada:
                activo.estado == EstadoSolicitud.enEjecucion ||
                activo.estado == EstadoSolicitud.conOfertas,
            onTap: () => _abrirDetalle(context, activo),
            acciones: [
              if (activo.estado == EstadoSolicitud.conOfertas)
                OutlinedButton.icon(
                  onPressed: () => _verOfertas(context, activo),
                  icon: const Icon(Icons.local_offer_rounded),
                  label: const Text('Ver ofertas'),
                )
              else if (activo.estado.conPiloto)
                OutlinedButton.icon(
                  onPressed: () => _seguir(context, activo),
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text('Ver seguimiento'),
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
                      ? 'Ver la otra solicitud activa'
                      : 'Ver las otras ${resumen.otrosActivos} solicitudes '
                            'activas',
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
              const _Seccion('Por calificar'),
              for (final s in resumen.porCalificar) ...[
                TarjetaSolicitud(
                  solicitud: s,
                  onTap: () => _abrirDetalle(context, s),
                  acciones: [
                    OutlinedButton.icon(
                      onPressed: () => mostrarHojaCalificar(context, s),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Calificar'),
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
              _Seccion('Avisos', primera: primero),
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
                'Historial reciente',
                primera: primero,
                accion: alVerServicios == null ? null : 'Ver todo',
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
                      solicitar,
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
            solicitar,
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
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Hola, $nombre', style: texto.headlineMedium),
        ),
        if (empresa != null) ...[
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            empresa!,
            style: texto.bodyLarge?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
        ],
      ],
    );
  }
}

/// La acción principal del inicio, destacada: una tarjeta grande con el
/// único botón lima de la pantalla.
class _TarjetaSolicitar extends StatelessWidget {
  const _TarjetaSolicitar({required this.alSolicitar});

  final VoidCallback alSolicitar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaGrande ?? 24;
    return Container(
      padding: const EdgeInsets.all(EspaciadoCampo.xl),
      decoration: BoxDecoration(
        color: ElevacionCampo.superficie(paleta, 2),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: paleta.borde),
        boxShadow: ElevacionCampo.sombras(paleta, 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUEVA SOLICITUD',
            style: texto.labelSmall?.copyWith(color: paleta.acentoTexto),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text('¿Qué lote fumigamos?', style: texto.headlineSmall),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            'Marca tu lote, propón un precio por hectárea y elige entre las '
            'ofertas de los pilotos.',
            style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrincipalMarketplace(
            key: const Key('inicio-solicitar'),
            texto: 'Publicar una solicitud',
            icono: Icons.arrow_forward_rounded,
            onPressed: alSolicitar,
          ),
        ],
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
                style: Theme.of(context).textTheme.titleLarge,
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
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
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
                  'No tienes solicitudes en curso',
                  style: texto.titleMedium,
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  'Publica tu primera solicitud y compara las ofertas de los pilotos.',
                  style: texto.bodyMedium?.copyWith(
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
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final (color, icono) = switch (aviso.tono) {
      TonoAvisoInicio.info => (paleta.info, Icons.wb_sunny_outlined),
      TonoAvisoInicio.alerta => (paleta.alerta, Icons.schedule_rounded),
    };
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaChica ?? 18;
    return Container(
      padding: const EdgeInsets.only(
        left: EspaciadoCampo.l,
        top: EspaciadoCampo.xs,
        bottom: EspaciadoCampo.m,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
                  Text(aviso.titulo, style: texto.titleMedium),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    aviso.detalle,
                    style: texto.bodyMedium?.copyWith(color: paleta.texto),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Descartar aviso',
            onPressed: () {
              HapticaCampo.seleccion();
              alDescartar();
            },
            icon: Icon(Icons.close_rounded, color: paleta.textoSecundario),
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
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
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
                              style: texto.titleMedium,
                            ),
                            const SizedBox(height: EspaciadoCampo.xs),
                            Text(
                              '${FormatoMarketplace.fechaCorta(solicitudes[i].ventanaDesde)} · '
                              '${FormatoMarketplace.hectareas(solicitudes[i].hectareas)}',
                              style: texto.bodyMedium?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (solicitudes[i].puntajeDelCliente != null)
                        Semantics(
                          label:
                              'Calificaste con '
                              '${solicitudes[i].puntajeDelCliente} de 5',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: paleta.alerta,
                                ),
                                const SizedBox(width: EspaciadoCampo.xs),
                                Text(
                                  '${solicitudes[i].puntajeDelCliente}',
                                  style: texto.titleMedium,
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

/// Esqueleto con la forma del inicio: saludo, tarjeta de solicitar, sección
/// y tarjeta de servicio.
class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: _margen(c.maxWidth),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EsqueletoCampo(alto: 32, ancho: 180),
            SizedBox(height: EspaciadoCampo.s),
            EsqueletoCampo(alto: 18, ancho: 220),
            SizedBox(height: EspaciadoCampo.xl),
            EsqueletoCampo(alto: 196, radio: 24),
            SizedBox(height: EspaciadoCampo.xxl),
            EsqueletoCampo(alto: 22, ancho: 150),
            SizedBox(height: EspaciadoCampo.l),
            EsqueletoCampo(alto: 164, radio: 18),
            SizedBox(height: EspaciadoCampo.xxl),
            EsqueletoCampo(alto: 22, ancho: 110),
            SizedBox(height: EspaciadoCampo.l),
            EsqueletoCampo(alto: 88, radio: 18),
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
                  ? 'Sin conexión'
                  : 'No pudimos cargar tu inicio',
              detalle: sinConexion
                  ? 'Revisa tu señal e intenta de nuevo. Publicar una '
                        'solicitud requiere conexión.'
                  : 'Intenta de nuevo en un momento.',
            ),
            OutlinedButton.icon(
              key: const Key('inicio-reintentar'),
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
          ],
        ),
      ),
    );
  }
}
