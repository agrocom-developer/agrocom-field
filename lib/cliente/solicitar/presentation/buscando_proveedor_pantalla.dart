import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/solicitud_repositorio.dart';
import 'busqueda_proveedor_cubit.dart';
import 'radar_busqueda.dart';

/// Lo que ve el cliente apenas confirma: la solicitud ya está creada y el
/// servicio se ofrece primero a los pilotos de Agrocom y después a
/// proveedores de la zona. No hay nada que el cliente tenga que hacer: puede
/// quedarse mirando o salir, y el servicio sigue su curso.
class BuscandoProveedorPantalla extends StatelessWidget {
  const BuscandoProveedorPantalla({
    required this.servicio,
    required this.alVerServicio,
    super.key,
  });

  final Servicio servicio;

  /// Abre el detalle del servicio; reemplaza esta pantalla.
  final VoidCallback alVerServicio;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BusquedaProveedorCubit(
        context.read<SolicitudRepositorio>(),
        servicio.id,
      )..iniciar(),
      child: BuscandoProveedorVista(
        servicio: servicio,
        alVerServicio: alVerServicio,
      ),
    );
  }
}

/// La interfaz de la búsqueda sobre un [BusquedaProveedorCubit] ya provisto.
class BuscandoProveedorVista extends StatelessWidget {
  const BuscandoProveedorVista({
    required this.servicio,
    required this.alVerServicio,
    super.key,
  });

  final Servicio servicio;
  final VoidCallback alVerServicio;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Scaffold(
      backgroundColor: paleta.fondo,
      body: SafeArea(
        child: BlocConsumer<BusquedaProveedorCubit, BusquedaProveedor>(
          listenWhen: (antes, ahora) =>
              antes.fase != ahora.fase && ahora.fase == FaseBusqueda.asignado,
          listener: (context, _) => HapticaCampo.confirmacion(),
          builder: (context, busqueda) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(EspaciadoCampo.xs),
                      child: IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                  Expanded(
                    // Centrado cuando entra; desplazable cuando no (texto
                    // ampliado, teléfono chico).
                    child: LayoutBuilder(
                      builder: (context, limites) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EspaciadoCampo.xl,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: limites.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: EspaciadoCampo.xl,
                              ),
                              child: _Contenido(
                                servicio: servicio,
                                busqueda: busqueda,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      EspaciadoCampo.l,
                      EspaciadoCampo.s,
                      EspaciadoCampo.l,
                      EspaciadoCampo.l,
                    ),
                    child: FilledButton(
                      key: const ValueKey('buscando-ver-servicio'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          ObjetivoTactilCampo.guantes,
                        ),
                      ),
                      onPressed: alVerServicio,
                      child: const Text(
                        'Ver el servicio',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.servicio, required this.busqueda});

  final Servicio servicio;
  final BusquedaProveedor busqueda;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final fase = busqueda.fase;
    final (titulo, detalle) = switch (fase) {
      FaseBusqueda.propios => (
        'Buscando proveedor',
        'Tu solicitud ya está creada. Primero se la ofrecemos a los pilotos '
            'de Agrocom.',
      ),
      FaseBusqueda.terceros => (
        'Buscando proveedor',
        'Ahora se la ofrecemos a proveedores verificados de la zona'
            '${busqueda.radioKm != null ? ', hasta ${busqueda.radioKm} km' : ''}.',
      ),
      FaseBusqueda.asignado => (
        'Proveedor asignado',
        'Aceptó tu solicitud. Vas a poder seguir el trabajo en vivo el día '
            'del servicio.',
      ),
      FaseBusqueda.sinProveedor => (
        'Todavía no hay proveedor',
        'Nadie pudo tomarla en esta ronda. Desde el servicio puedes ampliar '
            'la fecha o cancelarla sin costo.',
      ),
    };

    return Column(
      children: [
        AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          transitionBuilder: (hijo, animacion) => FadeTransition(
            opacity: animacion,
            child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(animacion),
              child: hijo,
            ),
          ),
          child: switch (fase) {
            FaseBusqueda.propios || FaseBusqueda.terceros => RadarBusqueda(
              key: const ValueKey('radar'),
              amplio: fase == FaseBusqueda.terceros,
            ),
            FaseBusqueda.asignado => _Sello(
              key: const ValueKey('sello-asignado'),
              icono: Icons.check_rounded,
              fondo: paleta.acento,
              color: paleta.sobreAcento,
            ),
            FaseBusqueda.sinProveedor => _Sello(
              key: const ValueKey('sello-sin-proveedor'),
              icono: Icons.search_off_rounded,
              fondo: paleta.texto.withValues(alpha: 0.08),
              color: paleta.textoSecundario,
            ),
          },
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: texto.headlineMedium,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        if (fase == FaseBusqueda.asignado && busqueda.proveedor != null)
          _TarjetaProveedor(busqueda.proveedor!)
        else
          _Rondas(fase: fase, radioKm: busqueda.radioKm),
        const SizedBox(height: EspaciadoCampo.l),
        Text(
          '${servicio.lote.nombre} · '
          '${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)} · '
          '${FormatoMarketplace.fechaConDia(servicio.fechaDeseada)}',
          textAlign: TextAlign.center,
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
        if (!busqueda.terminada) ...[
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            'Puedes cerrar esta pantalla: la búsqueda sigue y el servicio queda '
            'en tu inicio.',
            textAlign: TextAlign.center,
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ],
    );
  }
}

class _Sello extends StatelessWidget {
  const _Sello({
    required this.icono,
    required this.fondo,
    required this.color,
    super.key,
  });

  final IconData icono;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 220,
        child: Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
            child: Icon(icono, size: 56, color: color),
          ),
        ),
      ),
    );
  }
}

enum _EstadoRonda { enEspera, buscando, sinDisponibilidad }

/// Las dos rondas de la asignación, en orden: propios y después terceros.
class _Rondas extends StatelessWidget {
  const _Rondas({required this.fase, required this.radioKm});

  final FaseBusqueda fase;
  final int? radioKm;

  @override
  Widget build(BuildContext context) {
    final propios = fase == FaseBusqueda.propios
        ? _EstadoRonda.buscando
        : _EstadoRonda.sinDisponibilidad;
    final terceros = switch (fase) {
      FaseBusqueda.propios => _EstadoRonda.enEspera,
      FaseBusqueda.terceros => _EstadoRonda.buscando,
      _ => _EstadoRonda.sinDisponibilidad,
    };
    return SuperficieMarketplace(
      child: Column(
        children: [
          _Ronda(numero: 1, nombre: 'Pilotos de Agrocom', estado: propios),
          Divider(height: EspaciadoCampo.xl, color: context.paleta.borde),
          _Ronda(
            numero: 2,
            nombre: radioKm != null && terceros == _EstadoRonda.buscando
                ? 'Proveedores de la zona · $radioKm km'
                : 'Proveedores de la zona',
            estado: terceros,
          ),
        ],
      ),
    );
  }
}

class _Ronda extends StatelessWidget {
  const _Ronda({
    required this.numero,
    required this.nombre,
    required this.estado,
  });

  final int numero;
  final String nombre;
  final _EstadoRonda estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final activa = estado == _EstadoRonda.buscando;
    final (icono, leyenda) = switch (estado) {
      _EstadoRonda.enEspera => (Icons.schedule_rounded, 'Después'),
      _EstadoRonda.buscando => (Icons.radar_rounded, 'Buscando ahora'),
      _EstadoRonda.sinDisponibilidad => (
        Icons.remove_circle_outline_rounded,
        'Sin disponibilidad',
      ),
    };
    return MergeSemantics(
      child: Row(
        children: [
          Icon(
            icono,
            color: activa ? paleta.acentoTexto : paleta.textoSecundario,
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero. $nombre',
                  style: texto.titleMedium?.copyWith(
                    color: activa ? paleta.texto : paleta.textoSecundario,
                  ),
                ),
                Text(
                  leyenda,
                  style: texto.bodySmall?.copyWith(
                    color: activa ? paleta.acentoTexto : paleta.textoSecundario,
                    fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
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

class _TarjetaProveedor extends StatelessWidget {
  const _TarjetaProveedor(this.proveedor);

  final Proveedor proveedor;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return SuperficieMarketplace(
      resaltada: true,
      child: Row(
        children: [
          AvatarProveedor(proveedor, tamano: 56),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proveedor.nombre, style: texto.titleLarge),
                Text(
                  proveedor.tipo.etiqueta,
                  style: texto.bodySmall?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                CalificacionPromedio(
                  valor: proveedor.calificacion,
                  detalle: '${proveedor.serviciosCompletados} servicios',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
