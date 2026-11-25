import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tipografia_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../di/dependencias_negociacion.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'cifras_negociacion.dart';
import 'mapa_solicitudes.dart';
import 'mapa_solicitudes_cubit.dart';
import 'negociacion_pantalla.dart';
import 'ofertar_cubit.dart';
import 'pedir_precio_hoja.dart';
import 'solicitud_detalle_pantalla.dart';
import '../../../../../l10n/app_localizations.dart';

/// La pestaña «Mapa» del piloto (pantalla 14): un mapa a sangre con un lote y
/// un pin de precio por solicitud abierta (verde = abierta, ámbar = vence
/// hoy), búsqueda y filtros arriba, y una hoja inferior arrastrable con la
/// solicitud elegida (aceptar o contraofertar) y la lista completa.
///
/// El mapa es en línea: es una competencia entre pilotos y sin red no hay
/// nada que ver ni que ofertar (ADR 0016).
class MapaSolicitudesPantalla extends StatelessWidget {
  const MapaSolicitudesPantalla({this.reloj, super.key});

  /// Reloj para decidir qué vence hoy; por defecto, el del dispositivo.
  final DateTime Function()? reloj;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapaSolicitudesCubit(
        context.read<MercadoRepositorio>(),
        avisador: context.read<DependenciasNegociacion>().avisador,
      )..cargar(),
      child: MapaSolicitudesVista(reloj: reloj),
    );
  }
}

class MapaSolicitudesVista extends StatefulWidget {
  const MapaSolicitudesVista({this.reloj, super.key});

  final DateTime Function()? reloj;

  @override
  State<MapaSolicitudesVista> createState() => _MapaSolicitudesVistaState();
}

class _MapaSolicitudesVistaState extends State<MapaSolicitudesVista> {
  final _consulta = TextEditingController();
  final _hoja = DraggableScrollableController();
  bool _soloHoy = false;

  DateTime get _ahora => (widget.reloj ?? DateTime.now)();

  @override
  void dispose() {
    _consulta.dispose();
    _hoja.dispose();
    super.dispose();
  }

  /// Lo que se ve: lo cargado, acotado por la búsqueda y por «Vence hoy».
  List<SolicitudAbierta> _visibles(List<SolicitudAbierta> todas) {
    final q = _consulta.text.trim().toLowerCase();
    final ahora = _ahora;
    return [
      for (final s in todas)
        if ((!_soloHoy || venceHoy(s, ahora)) &&
            (q.isEmpty ||
                [
                  s.zona,
                  s.cultivo,
                  s.macrorregion?.etiqueta,
                ].any((t) => t != null && t.toLowerCase().contains(q))))
          s,
    ];
  }

  Future<void> _abrirDetalle(SolicitudAbierta s) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudDetallePantalla(solicitud: s),
      ),
    );
    if (mounted) context.read<MapaSolicitudesCubit>().cargar();
  }

  Future<void> _contraofertar(SolicitudAbierta s) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NegociacionPantalla(solicitudId: s.id, solicitud: s),
      ),
    );
    if (mounted) context.read<MapaSolicitudesCubit>().cargar();
  }

  Future<void> _filtrar() async {
    final cubit = context.read<MapaSolicitudesCubit>();
    final nuevos = await showModalBottomSheet<FiltrosMapa>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaFiltros(inicial: cubit.state.filtros),
    );
    if (nuevos != null) cubit.aplicarFiltros(nuevos);
  }

  void _seleccionar(SolicitudAbierta s) {
    final cubit = context.read<MapaSolicitudesCubit>();
    cubit.seleccionar(s.id);
    // La hoja sube lo justo para mostrar la solicitud y sus acciones.
    if (_hoja.isAttached && _hoja.size < _tamanoConSeleccion) {
      final duracion = MovimientoCampo.duracion(context, MovimientoCampo.media);
      if (duracion == Duration.zero) {
        _hoja.jumpTo(_tamanoConSeleccion);
      } else {
        _hoja.animateTo(
          _tamanoConSeleccion,
          duration: duracion,
          curve: MovimientoCampo.entrada,
        );
      }
    }
  }

  static const _tamanoConSeleccion = 0.62;
  static const _tamanoInicialHoja = 0.4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return BlocBuilder<MapaSolicitudesCubit, MapaSolicitudesEstado>(
      builder: (context, estado) {
        final cubit = context.read<MapaSolicitudesCubit>();
        final visibles = _visibles(estado.solicitudes);
        final elegida = [
          for (final s in visibles)
            if (s.id == estado.seleccionada) s,
        ].firstOrNull;
        final sinRed = estado.estado == EstadoMapa.sinRed;
        return LayoutBuilder(
          builder: (context, caja) => ColoredBox(
            color: paleta.fondo,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapaSolicitudes(
                    solicitudes: visibles,
                    seleccionada: estado.seleccionada,
                    ahora: _ahora,
                    alSeleccionar: _seleccionar,
                    // Los pines se encuadran entre la búsqueda y la hoja inferior,
                    // que tapan la parte de arriba y de abajo del mapa.
                    relleno: EdgeInsets.fromLTRB(
                      EspaciadoCampo.xxxl,
                      ObjetivoTactilCampo.campo * 2 + EspaciadoCampo.xxxl,
                      EspaciadoCampo.xxxl,
                      caja.maxHeight * _tamanoInicialHoja + EspaciadoCampo.xl,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (sinRed)
                        BannerSinSenalCampo(
                          mensaje:
                              l10n.proveedorNegociacionLasSolicitudesLasOfertas,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          EspaciadoCampo.l,
                          EspaciadoCampo.m,
                          EspaciadoCampo.l,
                          0,
                        ),
                        child: _Busqueda(
                          controlador: _consulta,
                          hayFiltros: estado.filtros.hayFiltros,
                          alCambiar: () => setState(() {}),
                          alFiltrar: _filtrar,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.s),
                      _FranjaFiltros(
                        filtros: estado.filtros,
                        soloHoy: _soloHoy,
                        alCambiarHoy: () =>
                            setState(() => _soloHoy = !_soloHoy),
                        alCambiarFiltros: cubit.aplicarFiltros,
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: HojaArrastrableCampo(
                    controlador: _hoja,
                    tamanoInicial: elegida == null
                        ? _tamanoInicialHoja
                        : _tamanoConSeleccion,
                    children: [
                      if (elegida != null) ...[
                        _SeleccionSolicitud(
                          key: ValueKey(elegida.id),
                          solicitud: elegida,
                          ahora: _ahora,
                          alContraofertar: () => _contraofertar(elegida),
                          alVerDetalle: () => _abrirDetalle(elegida),
                          alEnviada: cubit.cargar,
                        ),
                        const SizedBox(height: EspaciadoCampo.xl),
                      ],
                      _Cuerpo(
                        estado: estado,
                        visibles: visibles,
                        ahora: _ahora,
                        alElegir: _seleccionar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La píldora de búsqueda de 56 con el botón de filtros a la derecha.
class _Busqueda extends StatelessWidget {
  const _Busqueda({
    required this.controlador,
    required this.hayFiltros,
    required this.alCambiar,
    required this.alFiltrar,
  });

  final TextEditingController controlador;
  final bool hayFiltros;
  final VoidCallback alCambiar;
  final VoidCallback alFiltrar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.superficie,
        border: Border.all(color: paleta.borde),
        borderRadius: BorderRadius.circular(RadioCampo.capsula),
        boxShadow: ElevacionCampo.sombras(paleta, 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: paleta.esCampo
              ? ObjetivoTactilCampo.campo
              : ObjetivoTactilCampo.guantes,
        ),
        child: Row(
          children: [
            const SizedBox(width: EspaciadoCampo.l),
            Icon(Icons.search_rounded, color: paleta.textoSecundario),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Semantics(
                textField: true,
                label: l10n.proveedorNegociacionBuscarZonaLote,
                child: TextField(
                  controller: controlador,
                  onChanged: (_) => alCambiar(),
                  style: TipografiaCampo.cuerpo.copyWith(color: paleta.texto),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: EspaciadoCampo.l,
                    ),
                    hintText: l10n.proveedorNegociacionBuscarZonaLote,
                    hintStyle: TipografiaCampo.cuerpo.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: hayFiltros
                  ? l10n.proveedorNegociacionFiltrosHayFiltrosAplicados
                  : l10n.proveedorNegociacionFiltros,
              constraints: const BoxConstraints.tightFor(
                width: ObjetivoTactilCampo.guantes,
                height: ObjetivoTactilCampo.guantes,
              ),
              onPressed: alFiltrar,
              icon: Badge(
                isLabelVisible: hayFiltros,
                child: Icon(Icons.tune_rounded, color: paleta.texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filtros rápidos: lo que más se decide en el campo, de un toque.
class _FranjaFiltros extends StatelessWidget {
  const _FranjaFiltros({
    required this.filtros,
    required this.soloHoy,
    required this.alCambiarHoy,
    required this.alCambiarFiltros,
  });

  final FiltrosMapa filtros;
  final bool soloHoy;
  final VoidCallback alCambiarHoy;
  final ValueChanged<FiltrosMapa> alCambiarFiltros;

  static final _cincuenta = Decimal.fromInt(50);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cerca = filtros.orden == OrdenMapa.distancia;
    final grandes = filtros.hectareasMin == _cincuenta;
    return SizedBox(
      height: ObjetivoTactilCampo.guantes,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
        children: [
          _FiltroChip(
            etiqueta: l10n.proveedorNegociacionCerca,
            activo: cerca,
            alToque: () => alCambiarFiltros(
              filtros.copiarCon(
                orden: cerca ? OrdenMapa.reciente : OrdenMapa.distancia,
              ),
            ),
          ),
          _FiltroChip(
            etiqueta: l10n.proveedorNegociacion50Ha,
            activo: grandes,
            alToque: () => alCambiarFiltros(
              filtros.copiarCon(
                hectareasMin: () => grandes ? null : _cincuenta,
              ),
            ),
          ),
          _FiltroChip(
            etiqueta: l10n.proveedorNegociacionVenceHoy,
            activo: soloHoy,
            marca: true,
            alToque: alCambiarHoy,
          ),
          // Valles y Chiquitania primero: es la decisión que más se toma.
          for (final m in Macrorregion.ordenDeMapa)
            _FiltroChip(
              etiqueta: m.etiqueta,
              activo: filtros.macrorregion == m,
              alToque: () => alCambiarFiltros(
                filtros.copiarCon(
                  macrorregion: () => filtros.macrorregion == m ? null : m,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Filtro en píldora de 12 de radio: activo en grafito, inactivo en
/// superficie. [marca] pone el cuadrado ámbar de «vence hoy», el mismo color
/// que el lote en el mapa.
class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.etiqueta,
    required this.activo,
    required this.alToque,
    this.marca = false,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback alToque;
  final bool marca;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final tinta = activo ? paleta.sobreGrafito : paleta.texto;
    return Padding(
      padding: const EdgeInsets.only(right: EspaciadoCampo.s),
      child: Semantics(
        button: true,
        selected: activo,
        label: '$etiqueta${activo ? ', activo' : ''}',
        excludeSemantics: true,
        child: Material(
          color: activo ? paleta.grafito : paleta.superficie,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadioCampo.chip),
            side: BorderSide(color: activo ? paleta.grafito : paleta.borde),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadioCampo.chip),
            ),
            onTap: alToque,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: paleta.esCampo
                    ? ObjetivoTactilCampo.campo
                    : ObjetivoTactilCampo.guantes,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspaciadoCampo.l,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (marca) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: paleta.ambar,
                          borderRadius: BorderRadius.circular(
                            RadioCampo.xs / 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: EspaciadoCampo.s),
                    ],
                    Text(
                      etiqueta,
                      style: TipografiaCampo.tituloSeccion.copyWith(
                        fontSize: 15,
                        color: tinta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La solicitud elegida: lo que decide si se oferta (superficie y precio) y
/// las dos salidas. Aceptar manda la oferta al precio del cliente; es una
/// llamada directa y necesita red (ADR 0016).
class _SeleccionSolicitud extends StatelessWidget {
  const _SeleccionSolicitud({
    required this.solicitud,
    required this.ahora,
    required this.alContraofertar,
    required this.alVerDetalle,
    required this.alEnviada,
    super.key,
  });

  final SolicitudAbierta solicitud;
  final DateTime ahora;
  final VoidCallback alContraofertar;
  final VoidCallback alVerDetalle;
  final Future<void> Function() alEnviada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) =>
          OfertarCubit(context.read<MercadoRepositorio>(), l10n),
      child: BlocConsumer<OfertarCubit, OfertarEstado>(
        listenWhen: (a, b) =>
            a.estado != b.estado && b.estado == FaseOferta.enviada,
        listener: (context, _) {
          HapticaCampo.confirmacion();
          alEnviada();
        },
        builder: (context, ofertar) => _contenido(context, ofertar),
      ),
    );
  }

  Widget _contenido(BuildContext context, OfertarEstado ofertar) {
    final l10n = AppLocalizations.of(context);
    final s = solicitud;
    final paleta = context.paleta;
    final alto = paleta.esCampo
        ? ObjetivoTactilCampo.campo
        : ObjetivoTactilCampo.guantes;
    final hoy = venceHoy(s, ahora);
    final enviada = ofertar.estado == FaseOferta.enviada;
    final yaOferto = s.miNegociacion == MiNegociacion.vigente;
    final cerrada = s.miNegociacion == MiNegociacion.cerrada;
    final subtitulo = [
      ?s.zona,
      if (s.distanciaKm != null)
        'a ${FormatoMarketplace.kilometros(s.distanciaKm!)}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: EspaciadoCampo.m,
          runSpacing: EspaciadoCampo.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              subtitulo,
              style: TipografiaCampo.cuerpoSecundario.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
            ChipEstadoMarketplace(
              etiqueta: hoy
                  ? l10n.proveedorNegociacionVenceHoy
                  : l10n.proveedorNegociacionAbierta,
              tono: hoy ? TonoEstado.alerta : TonoEstado.exito,
              icono: hoy ? Icons.schedule_rounded : Icons.check_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(
          s.cultivo == null
              ? l10n.proveedorNegociacionSolicitudAbierta
              : l10n.proveedorNegociacionLote(s.cultivo!.toLowerCase()),
          style: TipografiaCampo.tituloPantalla.copyWith(color: paleta.texto),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        MosaicosSolicitud(solicitud: s),
        const SizedBox(height: EspaciadoCampo.m),
        Text(
          'Total al precio del cliente: ${FormatoMarketplace.bs(s.montoPropuesto)}'
          '${s.ofertasVigentes == 0 ? '' : ' · ${s.ofertasVigentes} ${s.ofertasVigentes == 1 ? 'oferta' : 'ofertas'}'}',
          style: TipografiaCampo.datoMono.copyWith(
            fontSize: 13,
            color: paleta.textoSecundario,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        if (ofertar.mensaje != null) ...[
          Semantics(
            liveRegion: true,
            child: ofertar.sinRed
                ? BannerSinSenalCampo(
                    mensaje:
                        l10n.proveedorNegociacionAceptarNecesitaRedReintenta,
                  )
                : AvisoMarketplace(
                    mensaje: ofertar.mensaje!,
                    tono: TonoAviso.error,
                  ),
          ),
          const SizedBox(height: EspaciadoCampo.m),
        ],
        if (enviada)
          AvisoMarketplace(
            mensaje: l10n.proveedorNegociacionOfertaEnviadaPorSigues(
              FormatoMarketplace.bs(ofertar.oferta!.precioHa),
            ),
            icono: Icons.check_circle_rounded,
          )
        else if (cerrada)
          AvisoMarketplace(
            mensaje: l10n.proveedorNegociacionNegociacionEstaSolicitudCerro,
            tono: TonoAviso.alerta,
          )
        else if (yaOferto)
          AvisoMarketplace(
            mensaje: l10n.proveedorNegociacionOfertasteAquiSigueNegociacion,
            icono: Icons.handshake_rounded,
            tono: TonoAviso.info,
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(alto),
                  ),
                  onPressed: ofertar.enviando ? null : alContraofertar,
                  child: Text(
                    l10n.proveedorNegociacionContraofertar,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: BotonPrincipalMarketplace(
                  texto: l10n.proveedorNegociacionAceptar(
                    CifrasNegociacion.bsHa(s.precioHaPropuesto),
                  ),
                  alto: alto,
                  cargando: ofertar.enviando,
                  onPressed: () => context.read<OfertarCubit>().ofertar(
                    solicitudId: s.id,
                    tipo: TipoOferta.aceptaPropuesta,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: EspaciadoCampo.s),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.minimo),
          ),
          onPressed: alVerDetalle,
          child: Text(l10n.proveedorNegociacionVerDetalleDelLote),
        ),
      ],
    );
  }
}

/// Bajo la solicitud elegida: la lista, el resumen por zona y los estados
/// (carga, vacío, error y sin red) con su salida.
class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.visibles,
    required this.ahora,
    required this.alElegir,
  });

  final MapaSolicitudesEstado estado;
  final List<SolicitudAbierta> visibles;
  final DateTime ahora;
  final ValueChanged<SolicitudAbierta> alElegir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapaSolicitudesCubit>();
    switch (estado.estado) {
      case EstadoMapa.cargando:
        return const Column(
          children: [
            EsqueletoCampo(alto: 112, radio: 18),
            SizedBox(height: EspaciadoCampo.m),
            EsqueletoCampo(alto: 112, radio: 18),
          ],
        );
      case EstadoMapa.sinRed:
        return EstadoErrorMarketplace(
          sinConexion: true,
          compacto: true,
          titulo: l10n.proveedorNegociacionSinConexion,
          detalle: l10n.proveedorNegociacionMapaSolicitudesNecesitaSenal,
          onReintentar: cubit.cargar,
        );
      case EstadoMapa.error:
        return EstadoErrorMarketplace(
          compacto: true,
          titulo: l10n.proveedorNegociacionPudimosCargarLasSolicitudes,
          detalle:
              estado.mensaje ?? l10n.proveedorNegociacionIntentaNuevoMomento,
          onReintentar: cubit.cargar,
        );
      case EstadoMapa.listo:
        if (visibles.isEmpty) {
          final hay =
              estado.filtros.hayFiltros || estado.solicitudes.isNotEmpty;
          return EstadoVacioMarketplace(
            icono: Icons.map_outlined,
            titulo: hay
                ? l10n.proveedorNegociacionNingunaSolicitudConEstos
                : l10n.proveedorNegociacionHaySolicitudesAbiertasAhora,
            detalle: hay
                ? l10n.proveedorNegociacionQuitaAlgunFiltroPrueba
                : l10n.proveedorNegociacionActivaLosAvisosPerfil,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${visibles.length} ${visibles.length == 1 ? 'solicitud abierta' : 'solicitudes abiertas'}',
              style: TipografiaCampo.tituloBloque.copyWith(
                fontSize: 17,
                color: context.paleta.texto,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            for (final s in visibles) ...[
              _TarjetaSolicitud(
                solicitud: s,
                hoy: venceHoy(s, ahora),
                resaltada: s.id == estado.seleccionada,
                alToque: () => alElegir(s),
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
            if (estado.hayMas)
              OutlinedButton(
                onPressed: estado.cargandoMas ? null : cubit.cargarMas,
                child: Text(
                  estado.cargandoMas
                      ? l10n.proveedorNegociacionCargando
                      : l10n.proveedorNegociacionVerMasSolicitudes,
                ),
              ),
            if (estado.zonas.isNotEmpty) ...[
              const SizedBox(height: EspaciadoCampo.l),
              _ResumenZonas(zonas: estado.zonas),
            ],
          ],
        );
    }
  }
}

class _ResumenZonas extends StatelessWidget {
  const _ResumenZonas({required this.zonas});

  final List<ResumenZona> zonas;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final porMacro = <Macrorregion?, List<ResumenZona>>{};
    for (final z in zonas) {
      porMacro.putIfAbsent(z.macrorregion, () => []).add(z);
    }
    return SuperficieMarketplace(
      radio: RadioCampo.tarjetaCompacta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.proveedorNegociacionDondeHayTrabajo,
            style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          for (final e in porMacro.entries) ...[
            Builder(
              builder: (context) {
                final cuantas = e.value.fold(0, (a, z) => a + z.solicitudes);
                final ha = e.value.fold(
                  Decimal.zero,
                  (a, z) => a + z.hectareas,
                );
                final nombre =
                    e.key?.etiqueta ?? l10n.proveedorNegociacionOtrasZonas;
                return Semantics(
                  container: true,
                  label: l10n.proveedorNegociacionSolicitudes(
                    nombre,
                    cuantas,
                    FormatoMarketplace.hectareas(ha),
                  ),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: EspaciadoCampo.xs,
                    ),
                    // `Wrap` y no `Row`: con texto grande la cifra baja de renglón.
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: EspaciadoCampo.m,
                      children: [
                        Text(
                          nombre,
                          style: TipografiaCampo.cuerpo.copyWith(
                            color: paleta.texto,
                          ),
                        ),
                        Text(
                          l10n.proveedorNegociacionHa(
                            cuantas,
                            CifrasNegociacion.ha(ha),
                          ),
                          style: TipografiaCampo.datoMono.copyWith(
                            fontSize: 14,
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({
    required this.solicitud,
    required this.hoy,
    required this.resaltada,
    required this.alToque,
  });

  final SolicitudAbierta solicitud;
  final bool hoy;
  final bool resaltada;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = solicitud;
    final paleta = context.paleta;
    return Semantics(
      button: true,
      selected: resaltada,
      label:
          'Solicitud en ${s.zona ?? 'zona sin nombre'}, '
          '${FormatoMarketplace.hectareas(s.hectareas)}, '
          '${FormatoMarketplace.bs(s.precioHaPropuesto)} por hectárea, '
          '${s.ofertasVigentes} ofertas${hoy ? ', vence hoy' : ''}',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        onTap: alToque,
        resaltada: resaltada,
        radio: RadioCampo.tarjetaCompacta,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: EspaciadoCampo.m,
              runSpacing: EspaciadoCampo.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  [?s.zona, ?s.cultivo].join(' · '),
                  style: TipografiaCampo.tituloBloque.copyWith(
                    fontSize: 17,
                    color: paleta.texto,
                  ),
                ),
                if (hoy)
                  ChipEstadoMarketplace(
                    etiqueta: l10n.proveedorNegociacionVenceHoy,
                    tono: TonoEstado.alerta,
                    icono: Icons.schedule_rounded,
                  )
                else if (s.miNegociacion != MiNegociacion.ninguna)
                  ChipEstadoMarketplace(
                    etiqueta: s.miNegociacion == MiNegociacion.vigente
                        ? l10n.proveedorNegociacionOfertaste
                        : l10n.proveedorNegociacionCerrada,
                    tono: s.miNegociacion == MiNegociacion.vigente
                        ? TonoEstado.info
                        : TonoEstado.neutro,
                    icono: s.miNegociacion == MiNegociacion.vigente
                        ? Icons.handshake_rounded
                        : Icons.lock_outline_rounded,
                  ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Wrap(
              spacing: EspaciadoCampo.xl,
              runSpacing: EspaciadoCampo.xs,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                CifraCampo(
                  valor: CifrasNegociacion.ha(s.hectareas),
                  unidad: 'ha',
                  estilo: TipografiaCampo.cifraMedia,
                ),
                CifraCampo(
                  valor: CifrasNegociacion.bsHa(s.precioHaPropuesto),
                  unidad: 'Bs/ha',
                  estilo: TipografiaCampo.cifraMedia,
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Text(
              [
                l10n.proveedorNegociacionTotal(
                  FormatoMarketplace.bs(s.montoPropuesto),
                ),
                s.ofertasVigentes == 0
                    ? l10n.proveedorNegociacionSinOfertas
                    : '${s.ofertasVigentes} ${s.ofertasVigentes == 1 ? 'oferta' : 'ofertas'}',
                if (s.distanciaKm != null)
                  FormatoMarketplace.kilometros(s.distanciaKm!),
              ].join(' · '),
              style: TipografiaCampo.datoMono.copyWith(
                fontSize: 13,
                color: paleta.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({required this.inicial});

  final FiltrosMapa inicial;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late final _haMin = TextEditingController(
    text: widget.inicial.hectareasMin?.toString() ?? '',
  );
  late final _haMax = TextEditingController(
    text: widget.inicial.hectareasMax?.toString() ?? '',
  );
  late final _precioMin = TextEditingController(
    text: widget.inicial.precioHaMin?.toString() ?? '',
  );
  late final _precioMax = TextEditingController(
    text: widget.inicial.precioHaMax?.toString() ?? '',
  );
  late final _cultivo = TextEditingController(
    text: widget.inicial.cultivo ?? '',
  );
  late OrdenMapa _orden = widget.inicial.orden;

  @override
  void dispose() {
    for (final c in [_haMin, _haMax, _precioMin, _precioMax, _cultivo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aplicar() {
    final cultivo = _cultivo.text.trim();
    Navigator.pop(
      context,
      FiltrosMapa(
        macrorregion: widget.inicial.macrorregion,
        zonaId: widget.inicial.zonaId,
        hectareasMin: leerPrecio(_haMin.text),
        hectareasMax: leerPrecio(_haMax.text),
        precioHaMin: leerPrecio(_precioMin.text),
        precioHaMax: leerPrecio(_precioMax.text),
        cultivo: cultivo.isEmpty ? null : cultivo,
        orden: _orden,
      ),
    );
  }

  void _limpiar() => Navigator.pop(
    context,
    FiltrosMapa(macrorregion: widget.inicial.macrorregion),
  );

  Widget _par(
    String a,
    TextEditingController ca,
    String b,
    TextEditingController cb,
  ) => Row(
    children: [
      Expanded(child: _numero(a, ca)),
      const SizedBox(width: EspaciadoCampo.m),
      Expanded(child: _numero(b, cb)),
    ],
  );

  Widget _numero(String etiqueta, TextEditingController c) =>
      CampoFormularioMarketplace(
        etiqueta: etiqueta,
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          0,
          EspaciadoCampo.l,
          EspaciadoCampo.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.proveedorNegociacionFiltrarSolicitudes,
              style: texto.titleLarge,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _par(
              l10n.proveedorNegociacionHectareasDesde,
              _haMin,
              l10n.proveedorNegociacionHectareasHasta,
              _haMax,
            ),
            const SizedBox(height: EspaciadoCampo.m),
            _par(
              l10n.proveedorNegociacionPorDesde,
              _precioMin,
              l10n.proveedorNegociacionPorHasta,
              _precioMax,
            ),
            const SizedBox(height: EspaciadoCampo.m),
            CampoFormularioMarketplace(
              etiqueta: l10n.proveedorNegociacionCultivo,
              controller: _cultivo,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text(l10n.proveedorNegociacionOrdenarPor, style: texto.titleMedium),
            const SizedBox(height: EspaciadoCampo.s),
            Wrap(
              spacing: EspaciadoCampo.s,
              children: [
                for (final o in OrdenMapa.values)
                  ChoiceChip(
                    label: Text(o.etiqueta),
                    selected: _orden == o,
                    onSelected: (_) => setState(() => _orden = o),
                  ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            BotonPrincipalMarketplace(
              texto: l10n.proveedorNegociacionVerSolicitudes,
              onPressed: _aplicar,
            ),
            const SizedBox(height: EspaciadoCampo.s),
            TextButton(
              onPressed: _limpiar,
              child: Text(l10n.proveedorNegociacionQuitarFiltros),
            ),
          ],
        ),
      ),
    );
  }
}
