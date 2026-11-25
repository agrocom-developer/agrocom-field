import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/boton_secundario.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/foto_remota.dart';
import '../../comun/presentation/hoja_precio.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/oferta_recibida.dart';
import '../domain/ofertas_repositorio.dart';
import 'ofertas_cubit.dart';
import 'perfil_proveedor_pantalla.dart';

/// Las ofertas que los pilotos hicieron a una solicitud: el cliente las
/// compara (precio, calificación, dron, distancia) y elige una. También
/// puede contraofertar o rechazar. El servidor decide qué procede; la
/// pantalla solo ofrece lo que él permite (ADR 0016).
class OfertasPantalla extends StatelessWidget {
  const OfertasPantalla({
    required this.solicitudId,
    this.reloj,
    this.intervalo = const Duration(seconds: 20),
    super.key,
  });

  final String solicitudId;

  /// Reloj para el tiempo que le queda a cada oferta; en pruebas, uno fijo.
  final DateTime Function()? reloj;

  /// Cada cuánto se vuelve a leer; `null` lo apaga.
  final Duration? intervalo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OfertasCubit(
        ofertas: context.read<OfertasRepositorio>(),
        solicitudes: context.read<SolicitudesRepositorio>(),
        solicitudId: solicitudId,
        intervalo: intervalo,
      )..cargar(),
      child: _Vista(reloj: reloj ?? DateTime.now),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.reloj});

  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OfertasCubit, OfertasEstado>(
      listenWhen: (a, b) => !a.adjudicada && b.adjudicada,
      listener: (context, estado) {
        HapticaCampo.confirmacion();
        // El piloto quedó elegido: de acá en adelante se sigue el trabajo.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                SeguimientoPantalla(solicitudId: estado.solicitud!.id),
          ),
        );
      },
      builder: (context, estado) {
        final cubit = context.read<OfertasCubit>();
        final recibidas = estado.fase == FaseOfertas.lista
            ? estado.vigentes(reloj()).length
            : null;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recibidas != null)
                  Text(
                    recibidas == 1
                        ? '1 oferta recibida'
                        : '$recibidas ofertas recibidas',
                    style: TipografiaCampo.cuerpoSecundario.copyWith(
                      color: context.paleta.textoSecundario,
                    ),
                  ),
                Text(
                  'Comparar ofertas',
                  style: TipografiaCampo.tituloSeccion.copyWith(
                    color: context.paleta.texto,
                  ),
                ),
              ],
            ),
          ),
          body: switch (estado.fase) {
            FaseOfertas.cargando => const _Cargando(),
            FaseOfertas.error => EstadoFalla(
              sinConexion: estado.sinConexion,
              queNoCargo: 'las ofertas',
              alReintentar: cubit.cargar,
            ),
            FaseOfertas.noEncontrada => const EstadoVacioMarketplace(
              icono: Icons.search_off_rounded,
              titulo: 'No encontramos esta solicitud',
              detalle: 'Vuelve a «Solicitudes» y ábrela de nuevo.',
            ),
            FaseOfertas.lista => _Lista(estado: estado, reloj: reloj),
          },
        );
      },
    );
  }
}

/// Máximo de rondas de una negociación: la quinta es definitiva. Solo para
/// mostrar «R3/5»; qué se puede responder lo decide el servidor
/// (`es_definitiva`, ADR 0016).
const int _rondasMaximas = 5;

class _Lista extends StatefulWidget {
  const _Lista({required this.estado, required this.reloj});

  final OfertasEstado estado;
  final DateTime Function() reloj;

  @override
  State<_Lista> createState() => _ListaState();
}

class _ListaState extends State<_Lista> {
  /// La oferta marcada «ELEGIDO»; si ya no está vigente, la primera a la
  /// que el cliente puede responder.
  String? _marcada;

  /// El piloto de la oferta marcada: una contraoferta reemplaza la oferta
  /// (cambia su id) pero la marca sigue con el mismo piloto.
  String? _marcadaProveedor;

  OfertaRecibida? _elegida(List<OfertaRecibida> vigentes, DateTime ahora) {
    for (final o in vigentes) {
      if (o.id == _marcada) return o;
    }
    for (final o in vigentes) {
      if (o.proveedor.id == _marcadaProveedor) return o;
    }
    for (final o in vigentes) {
      if (o.esperaAlCliente(ahora)) return o;
    }
    return vigentes.isEmpty ? null : vigentes.first;
  }

  /// Abre el perfil público del piloto; si toca «Elegir», sigue el mismo
  /// camino de confirmación que el botón de la barra.
  Future<void> _verPerfil(OfertaRecibida o, Solicitud s, DateTime ahora) async {
    final elegir = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PerfilProveedorPantalla(
          oferta: o,
          nombreLote: s.lote.nombre,
          puedeElegir: o.esperaAlCliente(ahora),
        ),
      ),
    );
    if ((elegir ?? false) && mounted) await _aceptar(o);
  }

  Future<void> _aceptar(OfertaRecibida o) async {
    final cubit = context.read<OfertasCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Elegir a ${o.proveedor.nombre}?'),
        content: Text(
          'Quedan acordados ${FormatoMarketplace.bs(o.precioHa)} por '
          'hectárea (${FormatoMarketplace.bs(o.montoEstimado)} estimados). '
          'Las demás ofertas se cierran y el piloto recibe tu contacto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const ValueKey('confirmar-aceptar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elegir piloto'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.aceptar(o);
  }

  Future<void> _contraofertar(OfertaRecibida o, Solicitud solicitud) async {
    final cubit = context.read<OfertasCubit>();
    final escrito = await mostrarHojaPrecio(
      context,
      titulo: 'Contraofertar a ${o.proveedor.nombre.split(' ').first}',
      textoAccion: 'Enviar contraoferta',
      hectareas: solicitud.hectareas,
      inicial: o.precioHa,
      conNota: true,
      apoyo:
          'Pide ${FormatoMarketplace.bs(o.precioHa)}/ha. Propón tu precio; '
          'el piloto puede aceptar o responder.',
    );
    if (escrito != null) {
      await cubit.contraofertar(o, escrito.precio, nota: escrito.nota);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final cubit = context.read<OfertasCubit>();
    final paleta = context.paleta;
    final s = estado.solicitud!;
    final ahora = widget.reloj();
    final vigentes = estado.vigentes(ahora);
    final cerradas = estado.cerradas(ahora);
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final cerradaLaSolicitud = !s.estado.negociando;
    final elegida = cerradaLaSolicitud ? null : _elegida(vigentes, ahora);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: cubit.actualizar,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    EspaciadoCampo.l,
                    margen,
                    EspaciadoCampo.xl,
                  ),
                  children: [
                    TicketPedidoCampo(
                      numero: 'PEDIDO #${s.id}',
                      estado: s.estado.etiqueta,
                      filas: [
                        FilaTicketCampo(clave: 'Lote', valor: s.lote.nombre),
                        FilaTicketCampo(
                          clave: 'Superficie',
                          valor: FormatoMarketplace.hectareasNumero(
                            s.hectareas,
                          ),
                          unidad: 'ha',
                          esCifra: true,
                        ),
                        FilaTicketCampo(
                          clave: 'Tu precio',
                          valor: FormatoMarketplace.bsNumero(
                            s.precioHaPropuesto,
                          ),
                          unidad: 'Bs/ha',
                          esCifra: true,
                        ),
                      ],
                    ),
                    if (estado.sinConexion) ...[
                      const SizedBox(height: EspaciadoCampo.l),
                      const AvisoMarketplace(
                        tono: TonoAviso.alerta,
                        icono: Icons.wifi_off_rounded,
                        mensaje:
                            'Sin conexión. Ves lo último que cargamos; puede '
                            'estar desactualizado.',
                      ),
                    ],
                    if (estado.aviso != null) ...[
                      const SizedBox(height: EspaciadoCampo.l),
                      _AvisoRespuesta(estado: estado),
                    ],
                    if (cerradaLaSolicitud) ...[
                      const SizedBox(height: EspaciadoCampo.l),
                      AvisoMarketplace(
                        key: const ValueKey('solicitud-cerrada'),
                        mensaje: switch (s.estado) {
                          EstadoSolicitud.expirada =>
                            'La solicitud expiró. Ábrela de nuevo para '
                                'recibir ofertas.',
                          EstadoSolicitud.cancelada =>
                            'La solicitud se canceló.',
                          _ => 'Ya elegiste a un piloto para esta solicitud.',
                        },
                      ),
                    ],
                    if (vigentes.isNotEmpty && !cerradaLaSolicitud) ...[
                      const SizedBox(height: EspaciadoCampo.l),
                      Text(
                        'OFERTAS · ORDEN: ${estado.orden.etiqueta.toUpperCase()}',
                        style: TipografiaCampo.etiquetaMono.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.s),
                      _Orden(orden: estado.orden, alCambiar: cubit.ordenar),
                    ],
                    const SizedBox(height: EspaciadoCampo.l),
                    if (vigentes.isEmpty && !cerradaLaSolicitud)
                      const _SinOfertas()
                    else
                      for (final o in vigentes) ...[
                        Padding(
                          key: ValueKey('oferta-${o.id}'),
                          padding: const EdgeInsets.only(
                            bottom: EspaciadoCampo.m,
                          ),
                          child: PostItOfertaCampo(
                            piloto: o.proveedor.nombre,
                            precioPorHectarea: FormatoMarketplace.bsNumero(
                              o.precioHa,
                            ),
                            total: FormatoMarketplace.bsNumero(o.montoEstimado),
                            detalle: _detallePostIt(o),
                            iniciales: o.proveedor.iniciales,
                            elegido: o.id == elegida?.id,
                            onTap: () {
                              HapticaCampo.seleccion();
                              setState(() {
                                _marcada = o.id;
                                _marcadaProveedor = o.proveedor.id;
                              });
                            },
                          ),
                        ),
                      ],
                    if (elegida != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: ValueKey('ver-perfil-${elegida.id}'),
                          onPressed: () => _verPerfil(elegida, s, ahora),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text(
                            AppLocalizations.of(context).perfilPublicoVerPerfil,
                          ),
                        ),
                      ),
                    if (elegida != null)
                      _DetalleOferta(
                        key: ValueKey('detalle-${elegida.id}'),
                        oferta: elegida,
                        solicitud: s,
                        ahora: ahora,
                      ),
                    if (cerradas.isNotEmpty) ...[
                      const TituloSeccionOfertas('Ofertas cerradas'),
                      for (final o in cerradas) _FilaCerrada(oferta: o),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (elegida != null)
          _BarraAcciones(
            oferta: elegida,
            ahora: ahora,
            margen: margen,
            ocupada: estado.respondiendo != null,
            respondiendoEsta: estado.respondiendo == elegida.id,
            alElegir: () => _aceptar(elegida),
            alContraofertar: () => _contraofertar(elegida, s),
            alRechazar: () => cubit.rechazar(elegida),
          ),
      ],
    );
  }

  /// «4,9/5 · 86 calificaciones · R3/5» (o «Aceptó tu precio»).
  static String _detallePostIt(OfertaRecibida o) {
    final p = o.proveedor;
    final nota = p.calificaciones == 0
        ? 'Sin calificaciones'
        : '${p.calificacion.toStringAsFixed(1).replaceAll('.', ',')}/5 · '
              '${p.calificaciones} '
              '${p.calificaciones == 1 ? 'calificación' : 'calificaciones'}';
    final estado = o.aceptaPropuesta
        ? 'Aceptó tu precio'
        : o.autor == AutorOferta.cliente
        ? 'Tu contraoferta · R${o.numero}/$_rondasMaximas'
        : 'R${o.numero}/$_rondasMaximas';
    return '$nota · $estado';
  }
}

/// Las acciones sobre la oferta marcada, ancladas abajo: elegir al piloto
/// (principal), contraofertar y rechazar. Si la respuesta le toca al piloto,
/// solo se dice que se espera.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.oferta,
    required this.ahora,
    required this.margen,
    required this.ocupada,
    required this.respondiendoEsta,
    required this.alElegir,
    required this.alContraofertar,
    required this.alRechazar,
  });

  final OfertaRecibida oferta;
  final DateTime ahora;
  final double margen;
  final bool ocupada;
  final bool respondiendoEsta;
  final VoidCallback alElegir;
  final VoidCallback alContraofertar;
  final VoidCallback alRechazar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final o = oferta;
    final primerNombre = o.proveedor.nombre.split(' ').first;
    final espera = o.esperaAlCliente(ahora);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(top: BorderSide(color: paleta.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margen,
            EspaciadoCampo.m,
            margen,
            EspaciadoCampo.s,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: espera
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BotonPrincipal(
                          key: ValueKey('aceptar-${o.id}'),
                          texto:
                              'Elegir a $primerNombre · '
                              '${FormatoMarketplace.bs(o.montoEstimado)}',
                          cargando: respondiendoEsta,
                          onPressed: ocupada ? null : alElegir,
                        ),
                        Row(
                          children: [
                            if (!o.esDefinitiva)
                              Expanded(
                                child: BotonSecundario(
                                  key: ValueKey('contraofertar-${o.id}'),
                                  texto: 'Contraofertar',
                                  icono: Icons.swap_vert_rounded,
                                  onPressed: ocupada ? null : alContraofertar,
                                ),
                              ),
                            Expanded(
                              child: BotonSecundario(
                                key: ValueKey('rechazar-${o.id}'),
                                texto: 'Rechazar',
                                icono: Icons.close_rounded,
                                onPressed: ocupada ? null : alRechazar,
                              ),
                            ),
                          ],
                        ),
                        if (o.esDefinitiva)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: EspaciadoCampo.xs,
                            ),
                            child: Text(
                              'Última ronda: solo puedes elegirlo o '
                              'rechazarlo.',
                              textAlign: TextAlign.center,
                              style: TipografiaCampo.cuerpoSecundario.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
                      child: Semantics(
                        liveRegion: true,
                        child: _Etiqueta(
                          texto: 'Esperando la respuesta de $primerNombre',
                          icono: Icons.hourglass_top_rounded,
                          rol: paleta.info,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección propio de las ofertas (separado del de otras pantallas
/// para no depender de su margen).
class TituloSeccionOfertas extends StatelessWidget {
  const TituloSeccionOfertas(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: EspaciadoCampo.xl,
      bottom: EspaciadoCampo.s,
    ),
    child: Semantics(
      header: true,
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class _Orden extends StatelessWidget {
  const _Orden({required this.orden, required this.alCambiar});

  final OrdenOfertas orden;
  final ValueChanged<OrdenOfertas> alCambiar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<OrdenOfertas>(
        showSelectedIcon: false,
        direction: MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? Axis.vertical
            : Axis.horizontal,
        segments: [
          for (final o in OrdenOfertas.values)
            ButtonSegment(value: o, label: Text(o.etiqueta)),
        ],
        selected: {orden},
        onSelectionChanged: (v) {
          HapticaCampo.seleccion();
          alCambiar(v.first);
        },
      ),
    );
  }
}

class _AvisoRespuesta extends StatelessWidget {
  const _AvisoRespuesta({required this.estado});

  final OfertasEstado estado;

  @override
  Widget build(BuildContext context) {
    final (tono, icono, mensaje) = switch (estado.aviso!) {
      AvisoOfertas.contraofertaEnviada => (
        TonoAviso.info,
        Icons.send_rounded,
        'Enviamos tu contraoferta. El piloto tiene que responder.',
      ),
      AvisoOfertas.rechazada => (
        TonoAviso.info,
        Icons.block_rounded,
        'Rechazaste la oferta. Las demás siguen abiertas.',
      ),
      AvisoOfertas.cambio => (
        TonoAviso.alerta,
        Icons.update_rounded,
        '${estado.mensajeAviso ?? 'La oferta cambió.'} Actualizamos la '
            'lista.',
      ),
      AvisoOfertas.sinConexion => (
        TonoAviso.error,
        Icons.wifi_off_rounded,
        'Sin conexión. No enviamos tu respuesta; inténtalo con señal.',
      ),
      AvisoOfertas.error => (
        TonoAviso.error,
        Icons.error_outline_rounded,
        estado.mensajeAviso ?? 'No pudimos enviar tu respuesta.',
      ),
    };
    return Semantics(
      liveRegion: true,
      child: AvisoMarketplace(
        key: const ValueKey('aviso-respuesta'),
        tono: tono,
        icono: icono,
        mensaje: mensaje,
      ),
    );
  }
}

class _SinOfertas extends StatelessWidget {
  const _SinOfertas();

  @override
  Widget build(BuildContext context) => const EstadoVacioMarketplace(
    icono: Icons.hourglass_empty_rounded,
    titulo: 'Todavía no hay ofertas',
    detalle:
        'Los pilotos de la zona ya ven tu solicitud. Cuando alguno ofrezca, '
        'te avisamos. Si tarda, prueba subir tu precio.',
  );
}

/// El detalle de la oferta marcada: cuánto se aparta de tu precio, la nota
/// del piloto, el dron, la distancia, cuánto vence y, si ya hubo rondas, la
/// conversación de precios en burbujas.
class _DetalleOferta extends StatelessWidget {
  const _DetalleOferta({
    required this.oferta,
    required this.solicitud,
    required this.ahora,
    super.key,
  });

  final OfertaRecibida oferta;
  final Solicitud solicitud;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final o = oferta;
    final p = o.proveedor;
    final restante = o.restante(ahora);
    final dif = o.precioHa - solicitud.precioHaPropuesto;
    final rondas = [...o.ronda, o];
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarFoto(
                iniciales: p.iniciales,
                etiqueta: 'Foto de ${p.nombre}',
                url: p.fotoUrl,
                tamano: ObjetivoTactilCampo.guantes - EspaciadoCampo.s,
              ),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Text(
                  o.autor == AutorOferta.cliente
                      ? 'Tu contraoferta · ronda ${o.numero}'
                      : o.aceptaPropuesta
                      ? 'Acepta tu precio'
                      : dif > Decimal.zero
                      ? 'Pide ${FormatoMarketplace.bs(dif)}/ha más que tu '
                            'precio'
                      : dif == Decimal.zero
                      ? 'Iguala tu precio'
                      : 'Ofrece ${FormatoMarketplace.bs(-dif)}/ha menos que '
                            'tu precio',
                  style: TipografiaCampo.tituloTarjeta.copyWith(
                    color: paleta.texto,
                  ),
                ),
              ),
            ],
          ),
          if (o.nota != null) ...[
            const SizedBox(height: EspaciadoCampo.m),
            Text(
              '«${o.nota}»',
              style: TipografiaCampo.cuerpo.copyWith(color: paleta.texto),
            ),
          ],
          const SizedBox(height: EspaciadoCampo.m),
          _Detalles(oferta: o, restante: restante),
          if (p.fotosDron.isNotEmpty) ...[
            const SizedBox(height: EspaciadoCampo.m),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in p.fotosDron) ...[
                    FotoRemota(
                      ruta: f.ruta,
                      ancho: 96,
                      alto: 72,
                      etiqueta: 'Foto del dron ${p.dron}',
                    ),
                    const SizedBox(width: EspaciadoCampo.s),
                  ],
                ],
              ),
            ),
          ],
          if (o.ronda.isNotEmpty) ...[
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              'RONDAS',
              style: TipografiaCampo.etiquetaMono.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            for (final r in rondas) ...[
              BurbujaNegociacionCampo(
                autor: r.autor == AutorOferta.cliente
                    ? AutorRonda.cliente
                    : AutorRonda.piloto,
                ronda: r.numero,
                precioPorHectarea: FormatoMarketplace.bsNumero(r.precioHa),
                total: FormatoMarketplace.bsNumero(r.montoEstimado),
                totalRondas: _rondasMaximas,
                esTurno: identical(r, o) && o.esperaAlCliente(ahora),
              ),
              const SizedBox(height: EspaciadoCampo.s),
            ],
          ],
        ],
      ),
    );
  }
}

class _Detalles extends StatelessWidget {
  const _Detalles({required this.oferta, required this.restante});

  final OfertaRecibida oferta;
  final Duration? restante;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = oferta.proveedor;
    final lineas = <(IconData, String)>[
      if (p.dron.isNotEmpty)
        (
          Icons.flight_rounded,
          '${p.dron}${p.capacidadLitros == null ? '' : ' · tanque de ${FormatoMarketplace.litros(p.capacidadLitros!)}'}',
        ),
      if (oferta.distanciaKm != null)
        (
          Icons.place_outlined,
          'A ${FormatoMarketplace.kilometros(oferta.distanciaKm!)} de tu lote',
        ),
      if (p.tasaCancelacion > 0)
        (
          Icons.event_busy_outlined,
          'Canceló ${(p.tasaCancelacion * 100).round()} % de sus servicios',
        ),
      if (restante != null)
        (
          Icons.timer_outlined,
          restante == Duration.zero
              ? 'La oferta venció'
              : 'Vence en ${FormatoMarketplace.duracionMinutos(restante!.inMinutes)}',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icono, linea) in lineas)
          Padding(
            padding: const EdgeInsets.only(bottom: EspaciadoCampo.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 18, color: paleta.textoSecundario),
                const SizedBox(width: EspaciadoCampo.s),
                Expanded(child: Text(linea, style: texto.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Píldora tonal con ícono: el par fondo/texto del rol (sin alpha).
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.icono,
    required this.rol,
  });

  final String texto;
  final IconData icono;
  final Color rol;

  @override
  Widget build(BuildContext context) {
    final (:fondo, texto: color) = context.paleta.contenedorDe(rol);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspaciadoCampo.m,
        vertical: EspaciadoCampo.s,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(RadioCampo.capsula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: EspaciadoCampo.xs),
          Flexible(
            child: Text(
              texto,
              style: TipografiaCampo.etiqueta.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCerrada extends StatelessWidget {
  const _FilaCerrada({required this.oferta});

  final OfertaRecibida oferta;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
      child: SuperficieMarketplace(
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
                  Text(oferta.proveedor.nombre, style: texto.titleSmall),
                  Text(
                    '${FormatoMarketplace.bs(oferta.precioHa)}/ha · '
                    'ronda ${oferta.numero}',
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: EspaciadoCampo.s),
            Text(
              oferta.estado == EstadoOferta.vigente
                  ? 'Vencida'
                  : oferta.estado.etiqueta,
              style: texto.labelMedium?.copyWith(color: paleta.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(EspaciadoCampo.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EsqueletoCampo(alto: 168, radio: RadioCampo.tarjeta),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 112, radio: RadioCampo.xs),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: 112, radio: RadioCampo.xs),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: 112, radio: RadioCampo.xs),
      ],
    ),
  );
}
