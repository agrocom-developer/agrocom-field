import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
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
        return Scaffold(
          appBar: AppBar(title: const Text('Ofertas')),
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

class _Lista extends StatelessWidget {
  const _Lista({required this.estado, required this.reloj});

  final OfertasEstado estado;
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OfertasCubit>();
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final s = estado.solicitud!;
    final ahora = reloj();
    final vigentes = estado.vigentes(ahora);
    final cerradas = estado.cerradas(ahora);
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final cerradaLaSolicitud = !s.estado.negociando;

    return RefreshIndicator(
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
              EspaciadoCampo.xxl,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  '${s.lote.nombre} · ${FormatoMarketplace.hectareas(s.hectareas)}',
                  style: texto.headlineSmall,
                ),
              ),
              Text(
                'Tu precio: ${FormatoMarketplace.bs(s.precioHaPropuesto)}/ha',
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
                      'La solicitud expiró. Ábrela de nuevo para recibir '
                          'ofertas.',
                    EstadoSolicitud.cancelada => 'La solicitud se canceló.',
                    _ => 'Ya elegiste a un piloto para esta solicitud.',
                  },
                ),
              ],
              if (vigentes.isNotEmpty && !cerradaLaSolicitud) ...[
                const SizedBox(height: EspaciadoCampo.l),
                _Orden(orden: estado.orden, alCambiar: cubit.ordenar),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              if (vigentes.isEmpty && !cerradaLaSolicitud)
                const _SinOfertas()
              else
                for (final o in vigentes) ...[
                  _TarjetaOferta(
                    key: ValueKey('oferta-${o.id}'),
                    oferta: o,
                    solicitud: s,
                    ahora: ahora,
                    ocupada: estado.respondiendo != null,
                    respondiendoEsta: estado.respondiendo == o.id,
                    mejorPrecio:
                        vigentes.length > 1 &&
                        o.precioHa ==
                            vigentes
                                .map((x) => x.precioHa)
                                .reduce((a, b) => a < b ? a : b),
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                ],
              if (cerradas.isNotEmpty) ...[
                const TituloSeccionOfertas('Ofertas cerradas'),
                for (final o in cerradas) _FilaCerrada(oferta: o),
              ],
            ],
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

class _TarjetaOferta extends StatelessWidget {
  const _TarjetaOferta({
    required this.oferta,
    required this.solicitud,
    required this.ahora,
    required this.ocupada,
    required this.respondiendoEsta,
    required this.mejorPrecio,
    super.key,
  });

  final OfertaRecibida oferta;
  final Solicitud solicitud;
  final DateTime ahora;

  /// Hay una respuesta viajando: se apagan las demás acciones.
  final bool ocupada;
  final bool respondiendoEsta;
  final bool mejorPrecio;

  Future<void> _aceptar(BuildContext context) async {
    final cubit = context.read<OfertasCubit>();
    final o = oferta;
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

  Future<void> _contraofertar(BuildContext context) async {
    final cubit = context.read<OfertasCubit>();
    final o = oferta;
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
    final cubit = context.read<OfertasCubit>();
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final o = oferta;
    final p = o.proveedor;
    final espera = o.esperaAlCliente(ahora);
    final restante = o.restante(ahora);
    final dif = o.precioHa - solicitud.precioHaPropuesto;
    return SuperficieMarketplace(
      resaltada: mejorPrecio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(proveedor: p),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: texto.titleMedium),
                    const SizedBox(height: 2),
                    p.calificaciones == 0
                        ? Text(
                            'Sin calificaciones todavía',
                            style: texto.bodySmall?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          )
                        : CalificacionPromedio(
                            valor: p.calificacion,
                            detalle:
                                '${p.calificaciones} '
                                '${p.calificaciones == 1 ? 'calificación' : 'calificaciones'}',
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.l),
          Wrap(
            spacing: EspaciadoCampo.s,
            runSpacing: EspaciadoCampo.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${FormatoMarketplace.bs(o.precioHa)}/ha',
                key: ValueKey('precio-${o.id}'),
                style: texto.headlineSmall,
              ),
              if (mejorPrecio)
                _Etiqueta(
                  texto: 'Mejor precio',
                  icono: Icons.trending_down_rounded,
                  color: paleta.acentoTexto,
                ),
            ],
          ),
          Text(
            '${FormatoMarketplace.bs(o.montoEstimado)} por '
            '${FormatoMarketplace.hectareas(solicitud.hectareas)}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            o.autor == AutorOferta.cliente
                ? 'Tu contraoferta · ronda ${o.numero}'
                : o.aceptaPropuesta
                ? 'Acepta tu precio'
                : dif > Decimal.zero
                ? 'Pide ${FormatoMarketplace.bs(dif)}/ha más que tu precio'
                : 'Ofrece ${FormatoMarketplace.bs(-dif)}/ha menos que tu precio',
            style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (o.nota != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text('«${o.nota}»', style: texto.bodyMedium),
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
          const SizedBox(height: EspaciadoCampo.l),
          if (espera) ...[
            BotonPrincipal(
              key: ValueKey('aceptar-${o.id}'),
              texto: 'Elegir a ${p.nombre.split(' ').first}',
              icono: Icons.check_rounded,
              cargando: respondiendoEsta,
              onPressed: ocupada ? null : () => _aceptar(context),
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Row(
              children: [
                if (!o.esDefinitiva)
                  Expanded(
                    child: BotonSecundario(
                      key: ValueKey('contraofertar-${o.id}'),
                      texto: 'Contraofertar',
                      icono: Icons.swap_vert_rounded,
                      onPressed: ocupada ? null : () => _contraofertar(context),
                    ),
                  ),
                Expanded(
                  child: BotonSecundario(
                    key: ValueKey('rechazar-${o.id}'),
                    texto: 'Rechazar',
                    icono: Icons.close_rounded,
                    onPressed: ocupada ? null : () => cubit.rechazar(o),
                  ),
                ),
              ],
            ),
            if (o.esDefinitiva)
              Text(
                'Última ronda: solo puedes elegirlo o rechazarlo.',
                style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
              ),
          ] else
            Semantics(
              liveRegion: true,
              child: _Etiqueta(
                texto: 'Esperando la respuesta de ${p.nombre.split(' ').first}',
                icono: Icons.hourglass_top_rounded,
                color: paleta.info,
              ),
            ),
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

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.icono,
    required this.color,
  });

  final String texto;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.proveedor});

  final ProveedorOfertante proveedor;

  @override
  Widget build(BuildContext context) => AvatarFoto(
    iniciales: proveedor.iniciales,
    etiqueta: 'Foto de ${proveedor.nombre}',
    url: proveedor.fotoUrl,
    tamano: 44,
  );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: EspaciadoCampo.xl, ancho: 220),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 220, radio: 18),
        SizedBox(height: EspaciadoCampo.m),
        EsqueletoCampo(alto: 220, radio: 18),
      ],
    ),
  );
}
