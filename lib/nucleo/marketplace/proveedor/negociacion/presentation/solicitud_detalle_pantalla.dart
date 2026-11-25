import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/esqueleto_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../terrenos/presentation/visor_fotos_terreno.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'negociacion_pantalla.dart';
import 'ofertar_cubit.dart';

/// El detalle de una solicitud abierta antes de ofertar: los lotes en el
/// mapa, el estado de la propiedad, lo que pide el cliente y las dos
/// acciones: aceptar el precio propuesto o contraofertar el tuyo.
class SolicitudDetallePantalla extends StatelessWidget {
  const SolicitudDetallePantalla({required this.solicitud, super.key});

  /// La fila del mapa; el detalle completo se pide al abrir.
  final SolicitudAbierta solicitud;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) =>
          OfertarCubit(context.read<MercadoRepositorio>(), l10n),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.solicitud.zona ?? l10n.proveedorNegociacionSolicitud,
        ),
      ),
      body: FutureBuilder<SolicitudAbierta>(
        future: _detalle,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final sinRed = snapshot.error is SinConexion;
            return EstadoErrorMarketplace(
              titulo: sinRed
                  ? l10n.proveedorNegociacionSinConexion
                  : l10n.proveedorNegociacionPudimosAbrirSolicitud,
              detalle: sinRed
                  ? l10n.proveedorNegociacionParaVerDetalleOfertar
                  : snapshot.error is OperacionRechazada
                  ? (snapshot.error! as OperacionRechazada).mensaje
                  : l10n.proveedorNegociacionIntentaNuevoMomento,
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
    final l10n = AppLocalizations.of(context);
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
                borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
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
                    l10n.proveedorNegociacionClientePropone,
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    l10n.proveedorNegociacionPor(
                      FormatoMarketplace.bs(s.precioHaPropuesto),
                    ),
                    style: texto.headlineSmall,
                  ),
                  Text(
                    l10n.proveedorNegociacionTotalEstimado(
                      FormatoMarketplace.bs(s.montoPropuesto),
                    ),
                    style: texto.bodyLarge,
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Text(
                    s.ofertasVigentes == 0
                        ? l10n.proveedorNegociacionTodaviaTieneOfertasPrimero
                        : s.ofertasVigentes == 1
                        ? l10n.proveedorNegociacionTieneOfertaVigente
                        : l10n.proveedorNegociacionTieneOfertasVigentes(
                            s.ofertasVigentes,
                          ),
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
              l10n.proveedorNegociacionContactoConClienteLlega,
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            if (enviada)
              AvisoMarketplace(
                mensaje: l10n.proveedorNegociacionOfertaEnviadaPorVes(
                  FormatoMarketplace.bs(ofertar.oferta!.precioHa),
                ),
                icono: Icons.check_circle_rounded,
              )
            else if (!s.puedeOfertar)
              AvisoMarketplace(
                mensaje: l10n.proveedorNegociacionNegociacionEstaSolicitudCerro,
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
        borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
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
    final l10n = AppLocalizations.of(context);
    final s = solicitud;
    final filas = <(String, String)>[
      if (s.ventanaDesde != null && s.ventanaHasta != null)
        (
          l10n.proveedorNegociacionFechaDeseada,
          l10n.proveedorNegociacionAl(
            FormatoMarketplace.fechaCorta(s.ventanaDesde!),
            FormatoMarketplace.fechaCorta(s.ventanaHasta!),
          ),
        ),
      if (s.tipoAplicacion != null)
        (
          l10n.proveedorNegociacionAplicacion,
          _capitalizar(s.tipoAplicacion!.replaceAll('_', ' ')),
        ),
      if (s.productoIndicado != null)
        (l10n.proveedorNegociacionProducto, s.productoIndicado!),
      if (s.aportaProducto != null)
        (
          l10n.proveedorNegociacionPoneProducto,
          s.aportaProducto == 'cliente'
              ? l10n.proveedorNegociacionCliente
              : l10n.proveedorNegociacionTu,
        ),
      if (s.urgente)
        (
          l10n.proveedorNegociacionUrgencia,
          l10n.proveedorNegociacionPideAtencionPronta,
        ),
      (
        l10n.proveedorNegociacionEstadoDelTerreno,
        s.accesoDificil
            ? l10n.proveedorNegociacionAccesoDificil
            : l10n.proveedorNegociacionAccesoNormal,
      ),
      if (s.referenciasAcceso != null)
        (l10n.proveedorNegociacionComoLlegar, s.referenciasAcceso!),
      if (s.colindantesSensibles != null)
        (l10n.proveedorNegociacionCuidar, s.colindantesSensibles!),
      if (s.observaciones != null)
        (l10n.proveedorNegociacionObservaciones, s.observaciones!),
      if (s.venceEn != null)
        (
          l10n.proveedorNegociacionAbiertaHasta,
          FormatoMarketplace.fechaLarga(s.venceEn!),
        ),
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

  /// La contraoferta se escribe en la pantalla de negociación (el stepper
  /// de ±1 Bs/ha con el total a la vista), no en una hoja de texto.
  Future<void> _contraofertar(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NegociacionPantalla(
            solicitudId: solicitud.id,
            solicitud: solicitud,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          texto: l10n.proveedorNegociacionAceptarPor(
            FormatoMarketplace.bs(solicitud.precioHaPropuesto),
          ),
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
          child: Text(l10n.proveedorNegociacionContraofertarPrecio),
        ),
      ],
    );
  }
}
