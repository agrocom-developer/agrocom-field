import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/pago/presentation/tarjetas_pago.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/barra_avance.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../comun/presentation/foto_remota.dart';
import '../../comun/presentation/linea_tiempo_solicitud.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';
import 'chat_pantalla.dart';
import 'mapa_ubicacion_piloto.dart';
import 'precio_final_pantalla.dart';
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
      child: BlocBuilder<SeguimientoCubit, SeguimientoEstado>(
        builder: (context, estado) => Scaffold(
          appBar: AppBar(
            title: _Titulo(
              apoyo: estado.solicitud?.estado.terminada ?? false
                  ? 'Servicio terminado'
                  : 'Servicio en curso',
              titulo: estado.solicitud?.lote.nombre ?? 'Seguimiento',
            ),
          ),
          body: AnimatedSwitcher(
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

class _Titulo extends StatelessWidget {
  const _Titulo({required this.apoyo, required this.titulo});

  final String apoyo;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          apoyo,
          style: TipografiaCampo.cuerpoSecundario.copyWith(
            color: paleta.textoSecundario,
          ),
        ),
        Text(
          titulo,
          style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado, required this.reloj, super.key});

  final SeguimientoEstado estado;
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
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
    // Las fotos, de la más reciente a la más antigua: las dos primeras van
    // en el mosaico y el resto en una tira.
    final fotos = a.fotos.reversed.toList();
    // Con el texto muy ampliado la tarjeta del piloto ocuparía media pantalla
    // anclada: pasa al final de la lista.
    final anclarPiloto = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final tarjetaPiloto = s.estado.conPiloto && s.nombreProveedor != null
        ? _TarjetaPiloto(solicitud: s, margen: margen)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<SeguimientoCubit>().actualizar,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    EspaciadoCampo.s,
                    margen,
                    EspaciadoCampo.xl,
                  ),
                  children: [
                    if (estado.sinConexion) ...[
                      const AvisoMarketplace(
                        tono: TonoAviso.alerta,
                        icono: Icons.wifi_off_rounded,
                        mensaje:
                            'Sin conexión. Ves lo último que cargamos; puede '
                            'estar desactualizado.',
                      ),
                      const SizedBox(height: EspaciadoCampo.l),
                    ],
                    _Avance(
                      solicitud: s,
                      avance: a,
                      ejecutadas: ejecutadas,
                      ahora: ahora,
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    if (fotos.isEmpty)
                      const _SinFotos()
                    else
                      _Mosaico(fotos: fotos, ahora: ahora),
                    if (fotos.length > 2) ...[
                      const TituloSeccion('Más fotos del avance'),
                      _Galeria(fotos: fotos.skip(2).toList(), ahora: ahora),
                    ],
                    const SizedBox(height: EspaciadoCampo.xl),
                    LineaTiempoSolicitud(
                      hitos: _hitos(s, a, fotos.length, ahora),
                    ),
                    if (s.estado.terminada) ...[
                      const SizedBox(height: EspaciadoCampo.l),
                      _PrecioFinal(solicitud: s),
                      if (int.tryParse(s.id) != null) ...[
                        const SizedBox(height: EspaciadoCampo.m),
                        TarjetaPagoDelCliente(solicitudId: int.parse(s.id)),
                      ],
                    ],
                    if (enEjecucion ||
                        s.estado == EstadoSolicitud.adjudicada) ...[
                      const TituloSeccion('Dónde está el piloto'),
                      _Ubicacion(
                        solicitud: s,
                        ubicacion: estado.ubicacion,
                        ahora: ahora,
                      ),
                    ],
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
                    if (!anclarPiloto && tarjetaPiloto != null) tarjetaPiloto,
                  ],
                ),
              ),
            ),
          ),
        ),
        if (anclarPiloto && tarjetaPiloto != null) tarjetaPiloto,
      ],
    );
  }

  /// Los cuatro pasos del servicio: piloto confirmado, inicio de vuelo,
  /// avance y cierre con precio final.
  static List<HitoSolicitud> _hitos(
    Solicitud s,
    AvanceServicio a,
    int fotos,
    DateTime ahora,
  ) {
    final terminada = s.estado.terminada;
    final enEjecucion = s.estado == EstadoSolicitud.enEjecucion;
    final inicio = a.iniciadaEn ?? s.momentoDe(EstadoSolicitud.enEjecucion);
    final porcentaje = (a.porcentaje ?? s.porcentajeAvance)?.toStringAsFixed(0);
    final ultima = a.ultimoAvanceEn;
    return [
      HitoSolicitud(
        clave: 'piloto',
        estado: EstadoHito.hecho,
        titulo: 'Piloto confirmado',
        detalle: s.nombreProveedor ?? 'El piloto',
        momento: s.momentoDe(EstadoSolicitud.adjudicada),
      ),
      HitoSolicitud(
        clave: 'inicio',
        estado: enEjecucion || terminada ? EstadoHito.hecho : EstadoHito.actual,
        titulo: 'Inicio de vuelo',
        detalle: 'Acuerden la fecha por el chat.',
        momento: inicio,
      ),
      HitoSolicitud(
        clave: 'avance',
        estado: terminada
            ? EstadoHito.hecho
            : enEjecucion
            ? EstadoHito.actual
            : EstadoHito.pendiente,
        titulo: 'Avance ${porcentaje ?? '0'} %',
        detalle:
            '$fotos ${fotos == 1 ? 'foto' : 'fotos'}'
            '${ultima == null ? '' : ' · ${FormatoMarketplace.hace(ultima, ahora)}'}',
      ),
      HitoSolicitud(
        clave: 'cierre',
        estado: terminada ? EstadoHito.hecho : EstadoHito.pendiente,
        titulo: 'Cierre y precio final',
        detalle: 'Al terminar el lote',
      ),
    ];
  }
}

/// «48 / 120 ha» en mono grande, la barra de avance y, debajo, el porcentaje
/// y el precio acordado.
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
    final s = solicitud;
    final iniciado =
        s.estado == EstadoSolicitud.enEjecucion || s.estado.terminada;
    final porcentaje = avance.porcentaje ?? s.porcentajeAvance;
    final hechas = ejecutadas == null
        ? '0'
        : FormatoMarketplace.hectareasNumero(ejecutadas!);
    final total = FormatoMarketplace.hectareasNumero(s.hectareas);
    final etiqueta = '$hechas de $total ha';
    final secundario = TipografiaCampo.datoMono.copyWith(
      color: paleta.textoSecundario,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: hechas,
                  style: TipografiaCampo.cifraDisplay.copyWith(
                    color: paleta.texto,
                  ),
                ),
                TextSpan(
                  text: ' / $total ha',
                  style: TipografiaCampo.cifraGrande.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        BarraAvance(
          valor: avance.progreso,
          etiqueta: etiqueta,
          alto: EspaciadoCampo.m,
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: EspaciadoCampo.m,
          children: [
            Text(
              iniciado ? '${porcentaje?.toStringAsFixed(0) ?? '0'} %' : '0 %',
              key: const ValueKey('avance-porcentaje'),
              style: secundario,
            ),
            Text(
              s.precioHaAcordado == null
                  ? '${FormatoMarketplace.bs(s.precioHaPropuesto)}/ha propuesto'
                  : '${FormatoMarketplace.bs(s.precioHaAcordado!)}/ha acordado',
              style: secundario,
            ),
          ],
        ),
        if (!iniciado) ...[
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            'El piloto todavía no empezó. Acuerden la fecha por el chat.',
            style: TipografiaCampo.cuerpo.copyWith(color: paleta.texto),
          ),
        ] else if (avance.ultimoAvanceEn != null) ...[
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            'Última actualización '
            '${FormatoMarketplace.hace(avance.ultimoAvanceEn!, ahora)}',
            style: TipografiaCampo.cuerpoSecundario.copyWith(
              color: paleta.textoSecundario,
            ),
          ),
        ],
      ],
    );
  }
}

/// Con el servicio terminado, el precio final se abre como ticket.
class _PrecioFinal extends StatelessWidget {
  const _PrecioFinal({required this.solicitud});

  final Solicitud solicitud;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final s = solicitud;
    return SuperficieMarketplace(
      resaltada: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PrecioFinalPantalla(solicitudId: s.id),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio final a pagar',
                  style: TipografiaCampo.cuerpoSecundario.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                CifraCampo(
                  key: const ValueKey('seguimiento-precio-final'),
                  valor: FormatoMarketplace.bsNumero(s.totalAPagar),
                  unidad: 'Bs',
                ),
                Text(
                  'Le pagas al piloto fuera de la app.',
                  style: TipografiaCampo.cuerpoSecundario.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: paleta.textoSecundario),
        ],
      ),
    );
  }
}

/// Anclada abajo: el piloto elegido y el acceso al chat.
class _TarjetaPiloto extends StatelessWidget {
  const _TarjetaPiloto({required this.solicitud, required this.margen});

  final Solicitud solicitud;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final nombre = solicitud.nombreProveedor!;
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          margen,
          EspaciadoCampo.s,
          margen,
          EspaciadoCampo.m,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SuperficieMarketplace(
              radio: RadioCampo.tarjeta,
              padding: const EdgeInsets.all(EspaciadoCampo.m),
              child: _FilaPiloto(
                avatar: AvatarFoto(
                  iniciales: iniciales,
                  etiqueta: 'Foto de $nombre',
                  tamano: ObjetivoTactilCampo.guantes - EspaciadoCampo.s,
                ),
                datos: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TipografiaCampo.tituloSeccion.copyWith(
                        color: paleta.texto,
                      ),
                    ),
                    Text(
                      'Tu piloto',
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
                boton: FilledButton.tonalIcon(
                  key: const ValueKey('abrir-chat'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPantalla(solicitudId: solicitud.id),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'),
                ),
              ),
            ),
          ),
        ),
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

/// Abre la foto a pantalla completa.
void _abrirFoto(BuildContext context, FotoAvance f) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: ColoresCampo.visorFoto,
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

/// Las dos últimas fotos y el total en un bloque ámbar; con una sola foto,
/// esa foto sola. Cada foto se abre a pantalla completa.
class _Mosaico extends StatelessWidget {
  const _Mosaico({required this.fotos, required this.ahora});

  /// De la más reciente a la más antigua; nunca vacía.
  final List<FotoAvance> fotos;
  final DateTime ahora;

  Widget _tocable(BuildContext context, FotoAvance f) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      key: ValueKey('foto-${f.id}'),
      onTap: () => _abrirFoto(context, f),
      child: FotoRemota(ruta: f.ruta),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ultima = fotos.first;
    if (fotos.length == 1) {
      return SizedBox(
        height: 240,
        child: Semantics(
          image: true,
          label: 'Foto del avance, ${FormatoMarketplace.hora(ultima.subidaEn)}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
            child: _tocable(context, ultima),
          ),
        ),
      );
    }
    final anterior = fotos[1];
    return CollageFotosCampo(
      principal: FotoCollageCampo(
        imagen: _tocable(context, ultima),
        hora: '${FormatoMarketplace.hora(ultima.subidaEn)} · ÚLTIMA',
        descripcion: 'Última foto del avance',
      ),
      secundaria: FotoCollageCampo(
        imagen: _tocable(context, anterior),
        hora: FormatoMarketplace.hora(anterior.subidaEn),
        descripcion: 'Foto anterior del avance',
      ),
      valorDato: '${fotos.length}',
      unidadDato: 'fotos',
      etiquetaDato: 'del servicio',
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.fotos, required this.ahora});

  final List<FotoAvance> fotos;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: EspaciadoCampo.s),
        itemBuilder: (context, i) {
          final f = fotos[i];
          return Semantics(
            button: true,
            label:
                'Foto del avance, '
                '${FormatoMarketplace.fechaCorta(f.subidaEn)} '
                '${FormatoMarketplace.hora(f.subidaEn)}. Toca para ampliar',
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('foto-${f.id}'),
              borderRadius: BorderRadius.circular(RadioCampo.chip),
              onTap: () => _abrirFoto(context, f),
              child: SizedBox(
                width: 128,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FotoRemota(ruta: f.ruta, ancho: 128, alto: 104),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      FormatoMarketplace.hace(f.subidaEn, ahora),
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
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
        EsqueletoCampo(alto: 14, radio: RadioCampo.capsula),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 240, radio: RadioCampo.tarjetaCompacta),
      ],
    ),
  );
}

/// Avatar, datos y botón en una fila; en columna con el texto muy ampliado.
class _FilaPiloto extends StatelessWidget {
  const _FilaPiloto({
    required this.avatar,
    required this.datos,
    required this.boton,
  });

  final Widget avatar;
  final Widget datos;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(child: datos),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.m),
          boton,
        ],
      );
    }
    return Row(
      children: [
        avatar,
        const SizedBox(width: EspaciadoCampo.m),
        Expanded(child: datos),
        const SizedBox(width: EspaciadoCampo.s),
        boton,
      ],
    );
  }
}
