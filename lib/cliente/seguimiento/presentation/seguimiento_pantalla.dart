import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/barra_avance.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../comun/presentation/foto_remota.dart';
import '../../comun/presentation/insignia_estado_solicitud.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';
import 'chat_pantalla.dart';
import 'mapa_ubicacion_piloto.dart';
import 'seguimiento_cubit.dart';

/// Seguimiento simple de un servicio adjudicado: cuánto lleva el piloto, las
/// fotos que subió, su última ubicación (un punto, sin ruta ni tiempo
/// estimado) y el acceso al chat. Lo operativo se acuerda en persona; la app
/// es el nexo y registra el estado (ADR 0017).
class SeguimientoPantalla extends StatelessWidget {
  const SeguimientoPantalla({
    required this.solicitudId,
    this.reloj,
    this.intervalo = const Duration(seconds: 15),
    super.key,
  });

  final String solicitudId;

  /// Reloj para «hace 2 min»; en pruebas, uno fijo.
  final DateTime Function()? reloj;

  /// Cada cuánto se vuelve a leer; `null` lo apaga.
  final Duration? intervalo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SeguimientoCubit(
        seguimiento: context.read<SeguimientoRepositorio>(),
        solicitudes: context.read<SolicitudesRepositorio>(),
        solicitudId: solicitudId,
        intervalo: intervalo,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Seguimiento')),
        body: BlocBuilder<SeguimientoCubit, SeguimientoEstado>(
          builder: (context, estado) => AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
            switchInCurve: MovimientoCampo.entrada,
            child: switch (estado.fase) {
              FaseSeguimiento.cargando => const _Cargando(
                key: ValueKey('carga'),
              ),
              FaseSeguimiento.error => EstadoFalla(
                key: const ValueKey('error'),
                sinConexion: estado.sinConexion,
                queNoCargo: 'el seguimiento',
                alReintentar: context.read<SeguimientoCubit>().cargar,
              ),
              FaseSeguimiento.noEncontrado => const EstadoVacioMarketplace(
                key: ValueKey('no-encontrado'),
                icono: Icons.search_off_rounded,
                titulo: 'No encontramos este servicio',
                detalle: 'Vuelve a «Solicitudes» y ábrelo de nuevo.',
              ),
              FaseSeguimiento.listo => _Contenido(
                key: const ValueKey('contenido'),
                estado: estado,
                reloj: reloj ?? DateTime.now,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado, required this.reloj, super.key});

  final SeguimientoEstado estado;
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = estado.solicitud!;
    final a = estado.avance ?? AvanceServicio.vacio(s.hectareas);
    final ahora = reloj();
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final enEjecucion = s.estado == EstadoSolicitud.enEjecucion;
    final ejecutadas = a.hectareasEjecutadas ?? s.hectareasEjecutadas;
    final notas = [
      for (final r in a.registros.reversed)
        if (r.nota != null && r.nota!.isNotEmpty) r,
    ];

    return RefreshIndicator(
      onRefresh: context.read<SeguimientoCubit>().actualizar,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              margen,
              EspaciadoCampo.l,
              margen,
              EspaciadoCampo.xxl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InsigniaEstadoSolicitud(s.estado),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Semantics(
                header: true,
                child: Text(s.lote.nombre, style: texto.headlineSmall),
              ),
              if (s.nombreProveedor != null)
                Text(
                  'Piloto: ${s.nombreProveedor}',
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              if (estado.sinConexion) ...[
                const SizedBox(height: EspaciadoCampo.l),
                const AvisoMarketplace(
                  tono: TonoAviso.alerta,
                  icono: Icons.wifi_off_rounded,
                  mensaje:
                      'Sin conexión. Ves lo último que cargamos; puede estar '
                      'desactualizado.',
                ),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              _Avance(
                solicitud: s,
                avance: a,
                ejecutadas: ejecutadas,
                ahora: ahora,
              ),
              if (s.estado.terminada) ...[
                const SizedBox(height: EspaciadoCampo.l),
                _PrecioFinal(solicitud: s),
              ],
              if (enEjecucion || s.estado == EstadoSolicitud.adjudicada) ...[
                const TituloSeccion('Dónde está el piloto'),
                _Ubicacion(
                  solicitud: s,
                  ubicacion: estado.ubicacion,
                  ahora: ahora,
                ),
              ],
              const TituloSeccion('Fotos del avance'),
              if (a.fotos.isEmpty)
                const _SinFotos()
              else
                _Galeria(fotos: a.fotos, ahora: ahora),
              if (notas.isNotEmpty) ...[
                const TituloSeccion('Notas del piloto'),
                SuperficieMarketplace(
                  child: ListaDatos([
                    for (final r in notas.take(5))
                      FilaDato(
                        '${FormatoMarketplace.fechaCorta(r.momento)}, '
                        '${FormatoMarketplace.hora(r.momento)}',
                        r.nota!,
                      ),
                  ]),
                ),
              ],
              if (s.estado.conPiloto) ...[
                const SizedBox(height: EspaciadoCampo.xl),
                BotonPrincipal(
                  key: const ValueKey('abrir-chat'),
                  texto: 'Escribirle al piloto',
                  icono: Icons.chat_bubble_outline_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPantalla(solicitudId: s.id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avance extends StatelessWidget {
  const _Avance({
    required this.solicitud,
    required this.avance,
    required this.ejecutadas,
    required this.ahora,
  });

  final Solicitud solicitud;
  final AvanceServicio avance;
  final Decimal? ejecutadas;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = solicitud;
    final iniciado =
        s.estado == EstadoSolicitud.enEjecucion || s.estado.terminada;
    final porcentaje = avance.porcentaje ?? s.porcentajeAvance;
    final etiqueta = ejecutadas == null
        ? '0 ha de ${FormatoMarketplace.hectareas(s.hectareas)}'
        : '${FormatoMarketplace.hectareas(ejecutadas!)} de '
              '${FormatoMarketplace.hectareas(s.hectareas)}';
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avance',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          if (!iniciado)
            Text(
              'El piloto todavía no empezó. Acuerden la fecha por el chat.',
              style: texto.bodyLarge,
            )
          else ...[
            Text(
              '${porcentaje?.toStringAsFixed(0) ?? '0'} %',
              key: const ValueKey('avance-porcentaje'),
              style: texto.displaySmall,
            ),
            const SizedBox(height: EspaciadoCampo.s),
            BarraAvance(valor: avance.progreso, etiqueta: etiqueta),
            const SizedBox(height: EspaciadoCampo.s),
            Text(etiqueta, style: texto.bodyMedium),
            if (avance.ultimoAvanceEn != null)
              Text(
                'Última actualización '
                '${FormatoMarketplace.hace(avance.ultimoAvanceEn!, ahora)}',
                style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrecioFinal extends StatelessWidget {
  const _PrecioFinal({required this.solicitud});

  final Solicitud solicitud;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final s = solicitud;
    return SuperficieMarketplace(
      resaltada: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precio final a pagar',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          Text(
            FormatoMarketplace.bs(s.totalAPagar),
            key: const ValueKey('seguimiento-precio-final'),
            style: texto.headlineMedium,
          ),
          Text(
            'Le pagas al piloto fuera de la app.',
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _Ubicacion extends StatelessWidget {
  const _Ubicacion({
    required this.solicitud,
    required this.ubicacion,
    required this.ahora,
  });

  final Solicitud solicitud;
  final UbicacionPiloto? ubicacion;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final u = ubicacion;
    final vigente = u != null && u.vigente;
    final mensaje = solicitud.estado != EstadoSolicitud.enEjecucion
        ? 'El piloto comparte su ubicación cuando empieza el trabajo.'
        : u == null
        ? 'Sin ubicación reciente. Escríbele por el chat si necesitas '
              'saber dónde está.'
        : vigente
        ? 'Última ubicación ${FormatoMarketplace.hace(u.capturadaEn, ahora)}.'
        : 'Sin ubicación reciente. La última fue '
              '${FormatoMarketplace.hace(u.capturadaEn, ahora)}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: MapaUbicacionPiloto(
            lote: solicitud.lote,
            punto: u?.punto,
            vigente: vigente,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Semantics(
          liveRegion: true,
          child: Text(
            mensaje,
            key: const ValueKey('ubicacion-mensaje'),
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ),
      ],
    );
  }
}

class _SinFotos extends StatelessWidget {
  const _SinFotos();

  @override
  Widget build(BuildContext context) => const AvisoMarketplace(
    mensaje:
        'Todavía no hay fotos. El piloto las sube a medida que avanza, y '
        'las verás acá.',
  );
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.fotos, required this.ahora});

  final List<FotoAvance> fotos;
  final DateTime ahora;

  void _abrir(BuildContext context, FotoAvance f) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: FotoRemota(ruta: f.ruta, etiqueta: 'Foto del avance'),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton.filled(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: EspaciadoCampo.s),
        itemBuilder: (context, i) {
          final f = fotos[fotos.length - 1 - i];
          return Semantics(
            button: true,
            label:
                'Foto del avance, '
                '${FormatoMarketplace.fechaCorta(f.subidaEn)} '
                '${FormatoMarketplace.hora(f.subidaEn)}. Toca para ampliar',
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('foto-${f.id}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _abrir(context, f),
              child: SizedBox(
                width: 128,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FotoRemota(ruta: f.ruta, ancho: 128, alto: 104),
                    const SizedBox(height: 2),
                    Text(
                      FormatoMarketplace.hace(f.subidaEn, ahora),
                      style: texto.bodySmall?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(EspaciadoCampo.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: EspaciadoCampo.xl, ancho: 140),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: EspaciadoCampo.xxl, ancho: 220),
        SizedBox(height: EspaciadoCampo.xl),
        EsqueletoCampo(alto: 140, radio: 18),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 200, radio: 18),
      ],
    ),
  );
}
