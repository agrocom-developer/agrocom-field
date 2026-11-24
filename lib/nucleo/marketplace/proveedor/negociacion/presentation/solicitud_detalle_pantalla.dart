import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/esqueleto_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../terrenos/presentation/visor_fotos_terreno.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'ofertar_cubit.dart';
import 'pedir_precio_hoja.dart';

/// El detalle de una solicitud abierta antes de ofertar: los lotes en el
/// mapa, el estado de la propiedad, lo que pide el cliente y las dos
/// acciones: aceptar el precio propuesto o contraofertar el tuyo.
class SolicitudDetallePantalla extends StatelessWidget {
  const SolicitudDetallePantalla({required this.solicitud, super.key});

  /// La fila del mapa; el detalle completo se pide al abrir.
  final SolicitudAbierta solicitud;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OfertarCubit(context.read<MercadoRepositorio>()),
      child: _Vista(solicitud: solicitud),
    );
  }
}

class _Vista extends StatefulWidget {
  const _Vista({required this.solicitud});

  final SolicitudAbierta solicitud;

  @override
  State<_Vista> createState() => _VistaState();
}

class _VistaState extends State<_Vista> {
  late Future<SolicitudAbierta> _detalle = _pedir();

  Future<SolicitudAbierta> _pedir() =>
      context.read<MercadoRepositorio>().detalle(widget.solicitud.id);

  void _reintentar() => setState(() => _detalle = _pedir());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.solicitud.zona ?? 'Solicitud')),
      body: FutureBuilder<SolicitudAbierta>(
        future: _detalle,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final sinRed = snapshot.error is SinConexion;
            return EstadoErrorMarketplace(
              titulo: sinRed ? 'Sin conexión' : 'No pudimos abrir la solicitud',
              detalle: sinRed
                  ? 'Para ver el detalle y ofertar necesitas señal. '
                        'Reintenta cuando la tengas.'
                  : snapshot.error is OperacionRechazada
                  ? (snapshot.error! as OperacionRechazada).mensaje
                  : 'Intenta de nuevo en un momento.',
              onReintentar: _reintentar,
            );
          }
          final s = snapshot.data;
          // Mientras llega el detalle se muestra la fila del mapa.
          return _Contenido(
            solicitud: s ?? widget.solicitud,
            cargandoDetalle: s == null,
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.solicitud, required this.cargandoDetalle});

  final SolicitudAbierta solicitud;
  final bool cargandoDetalle;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final s = solicitud;
    return BlocConsumer<OfertarCubit, OfertarEstado>(
      listener: (context, estado) {
        if (estado.estado == FaseOferta.enviada) HapticaCampo.confirmacion();
      },
      builder: (context, ofertar) {
        final enviada = ofertar.estado == FaseOferta.enviada;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            if (s.terreno != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 200,
                  child: MapaLote(
                    lotes: [s.terreno!],
                    seleccionado: s.terreno,
                    interactivo: false,
                  ),
                ),
              )
            else if (cargandoDetalle)
              const _HuecoMapa(),
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              '${FormatoMarketplace.hectareas(s.hectareas)}'
              '${s.cultivo == null ? '' : ' de ${s.cultivo!.toLowerCase()}'}',
              style: texto.headlineMedium,
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              [?s.zona, ?s.macrorregion?.etiqueta].join(' · '),
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            SuperficieMarketplace(
              resaltada: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El cliente propone',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    '${FormatoMarketplace.bs(s.precioHaPropuesto)} por ha',
                    style: texto.headlineSmall,
                  ),
                  Text(
                    'Total estimado ${FormatoMarketplace.bs(s.montoPropuesto)}',
                    style: texto.bodyLarge,
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Text(
                    s.ofertasVigentes == 0
                        ? 'Todavía no tiene ofertas: sé el primero.'
                        : s.ofertasVigentes == 1
                        ? 'Ya tiene 1 oferta vigente.'
                        : 'Ya tiene ${s.ofertasVigentes} ofertas vigentes.',
                    style: texto.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _Datos(solicitud: s),
            const SizedBox(height: EspaciadoCampo.l),
            if (cargandoDetalle)
              const EsqueletoCampo(alto: 120, radio: 14)
            else
              VisorFotosTerreno(fotos: s.terreno?.fotos ?? const []),
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              'Tu contacto con el cliente llega solo si te eligen. Hasta '
              'entonces no ves su nombre, teléfono ni dirección.',
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            if (enviada)
              AvisoMarketplace(
                mensaje:
                    'Oferta enviada: ${FormatoMarketplace.bs(ofertar.oferta!.precioHa)} '
                    'por ha. La ves en «Mis ofertas».',
                icono: Icons.check_circle_rounded,
              )
            else if (!s.puedeOfertar)
              const AvisoMarketplace(
                mensaje:
                    'Tu negociación en esta solicitud ya se cerró. No puedes '
                    'ofertar de nuevo.',
                tono: TonoAviso.alerta,
              )
            else
              _Acciones(solicitud: s, estado: ofertar),
          ],
        );
      },
    );
  }
}

/// El hueco del mapa mientras llega el detalle.
class _HuecoMapa extends StatelessWidget {
  const _HuecoMapa();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: context.paleta.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.paleta.borde),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _Datos extends StatelessWidget {
  const _Datos({required this.solicitud});

  final SolicitudAbierta solicitud;

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final filas = <(String, String)>[
      if (s.ventanaDesde != null && s.ventanaHasta != null)
        (
          'Fecha deseada',
          '${FormatoMarketplace.fechaCorta(s.ventanaDesde!)} al '
              '${FormatoMarketplace.fechaCorta(s.ventanaHasta!)}',
        ),
      if (s.tipoAplicacion != null)
        ('Aplicación', _capitalizar(s.tipoAplicacion!.replaceAll('_', ' '))),
      if (s.productoIndicado != null) ('Producto', s.productoIndicado!),
      if (s.aportaProducto != null)
        (
          'Pone el producto',
          s.aportaProducto == 'cliente' ? 'El cliente' : 'Tú',
        ),
      if (s.urgente) ('Urgencia', 'Pide atención pronta'),
      (
        'Estado del terreno',
        s.accesoDificil ? 'Acceso difícil' : 'Acceso normal',
      ),
      if (s.referenciasAcceso != null) ('Cómo llegar', s.referenciasAcceso!),
      if (s.colindantesSensibles != null) ('Cuidar', s.colindantesSensibles!),
      if (s.observaciones != null) ('Observaciones', s.observaciones!),
      if (s.venceEn != null)
        ('Abierta hasta', FormatoMarketplace.fechaLarga(s.venceEn!)),
    ];
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const Divider(height: EspaciadoCampo.xl),
            _Fila(etiqueta: filas[i].$1, valor: filas[i].$2),
          ],
        ],
      ),
    );
  }

  static String _capitalizar(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: texto.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: 2),
          Text(valor, style: texto.bodyLarge),
        ],
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({required this.solicitud, required this.estado});

  final SolicitudAbierta solicitud;
  final OfertarEstado estado;

  Future<void> _contraofertar(BuildContext context) async {
    final cubit = context.read<OfertarCubit>();
    final propuesta = await pedirPrecio(
      context,
      titulo: 'Tu contraoferta',
      hectareas: solicitud.hectareas,
      precioReferencia: solicitud.precioHaPropuesto,
      etiquetaReferencia: 'El cliente propone',
      tipoAplicacion: solicitud.tipoAplicacion ?? 'otro',
      zonaId: solicitud.zonaId,
      macrorregion: solicitud.macrorregion?.codigo,
    );
    if (propuesta == null) return;
    await cubit.ofertar(
      solicitudId: solicitud.id,
      tipo: TipoOferta.contraoferta,
      precioHa: propuesta.precioHa,
      nota: propuesta.nota,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OfertarCubit>();
    final enviando = estado.enviando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estado.mensaje != null) ...[
          AvisoMarketplace(
            mensaje: estado.mensaje!,
            tono: estado.sinRed ? TonoAviso.alerta : TonoAviso.error,
            icono: estado.sinRed ? Icons.wifi_off_rounded : null,
          ),
          const SizedBox(height: EspaciadoCampo.m),
        ],
        BotonPrincipalMarketplace(
          texto:
              'Aceptar ${FormatoMarketplace.bs(solicitud.precioHaPropuesto)} por ha',
          cargando: enviando,
          onPressed: () => cubit.ofertar(
            solicitudId: solicitud.id,
            tipo: TipoOferta.aceptaPropuesta,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
          ),
          onPressed: enviando ? null : () => _contraofertar(context),
          child: const Text('Contraofertar mi precio'),
        ),
      ],
    );
  }
}
