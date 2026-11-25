import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../pago/presentation/tarjetas_pago.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../../negociacion/presentation/chat_pantalla.dart';
import '../../negociacion/presentation/pedir_precio_hoja.dart' show leerPrecio;
import '../di/dependencias_ejecucion.dart';
import '../domain/ejecucion.dart';
import 'ejecucion_cubits.dart';
import 'servicios_lote_pantalla.dart';

/// Un servicio adjudicado en el lote. Todo lo que se hace aquí se guarda en
/// el dispositivo y se sube cuando hay señal; la pantalla nunca espera al
/// servidor. Lo operativo (cómo trabajar el lote) se acuerda en persona: la
/// app solo sube fotos de avance, marca el progreso y muestra el precio.
class ServicioLotePantalla extends StatelessWidget {
  const ServicioLotePantalla({required this.servicioId, super.key});

  final int servicioId;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<DependenciasEjecucion>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ServicioLoteCubit(
            deps.repositorio,
            servicioId,
            selector: deps.selectorFoto,
          )..iniciar(),
        ),
        BlocProvider(
          create: (context) =>
              UbicacionCubit(deps.ubicacion, deps.publicador, servicioId),
        ),
      ],
      child: const ServicioLoteVista(),
    );
  }
}

class ServicioLoteVista extends StatelessWidget {
  const ServicioLoteVista({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ServicioLoteCubit, ServicioLoteEstado>(
      // Solo se comparte la ubicación con el servicio en ejecución.
      listenWhen: (a, b) => a.servicio?.estado != b.servicio?.estado,
      listener: (context, estado) {
        final ubicacion = context.read<UbicacionCubit>();
        if (!context.read<DependenciasEjecucion>().compartirUbicacion) return;
        if (estado.servicio?.estado == EstadoServicioLote.enEjecucion) {
          ubicacion.iniciar();
        } else {
          ubicacion.detener();
        }
      },
      builder: (context, estado) {
        final s = estado.servicio;
        return Scaffold(
          appBar: AppBar(
            title: Text(s?.terreno?.nombre ?? l10n.proveedorEjecucionServicio),
            actions: [
              if (s != null && s.estado != EstadoServicioLote.finalizada)
                IconButton(
                  tooltip: l10n.proveedorEjecucionChatConCliente,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPantalla(solicitudId: s.id),
                    ),
                  ),
                ),
            ],
          ),
          body: estado.cargando
              ? const Center(child: CircularProgressIndicator())
              : s == null
              ? EstadoVacioMarketplace(
                  icono: Icons.search_off_rounded,
                  titulo: l10n.proveedorEjecucionEncontramosEsteServicio,
                  detalle: l10n.proveedorEjecucionPuedeQueClienteHaya,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lo posterior a la adjudicación es offline-first: con
                    // algo por subir, el banner lo dice y no se pierde nada.
                    if (s.pendientes > 0 && s.rechazos == 0)
                      BannerSinSenalCampo(
                        mensaje: l10n.proveedorEjecucionTusFotosAvancesQuedan,
                      ),
                    Expanded(
                      child: _Contenido(servicio: s, estado: estado),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.servicio, required this.estado});

  final ServicioEnLote servicio;
  final ServicioLoteEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final (tono, icono) = estiloEstado(s.estado);
    final lista = ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        if (s.terreno != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
            child: SizedBox(
              height: 190,
              child: MapaLote(
                lotes: [s.terreno!],
                seleccionado: s.terreno,
                interactivo: false,
              ),
            ),
          ),
          const SizedBox(height: EspaciadoCampo.l),
        ],
        Text(
          '${FormatoMarketplace.hectareas(s.hectareas)}'
          '${s.cultivo == null ? '' : ' · ${s.cultivo}'}',
          style: texto.headlineSmall,
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: ChipEstadoMarketplace(
            etiqueta: s.estado.etiqueta,
            tono: tono,
            icono: icono,
          ),
        ),
        if (estado.aviso != null) ...[
          const SizedBox(height: EspaciadoCampo.m),
          Semantics(
            liveRegion: true,
            child: AvisoMarketplace(
              mensaje: estado.aviso!,
              tono: estado.avisoEsError ? TonoAviso.error : TonoAviso.info,
              icono: estado.avisoEsError ? null : Icons.check_circle_rounded,
            ),
          ),
        ],
        if (s.pendientes > 0 || s.rechazos > 0) ...[
          const SizedBox(height: EspaciadoCampo.m),
          ChipPendientes(servicio: s),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            s.rechazos > 0
                ? l10n.proveedorEjecucionServidorAceptoAlgoQue
                : l10n.proveedorEjecucionEstaGuardadoEsteCelular,
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ],
        const SizedBox(height: EspaciadoCampo.l),
        if (s.estado == EstadoServicioLote.enEjecucion) ...[
          _Avance(servicio: s),
          const SizedBox(height: EspaciadoCampo.l),
        ],
        if (s.estado == EstadoServicioLote.finalizada) ...[
          _PrecioFinal(servicio: s),
          const SizedBox(height: EspaciadoCampo.l),
          TarjetaConfirmarPago(solicitudId: s.id),
        ] else if (s.estado == EstadoServicioLote.enEjecucion)
          _AccionesSecundarias(servicio: s, ocupado: estado.ocupado),
        if (s.estado == EstadoServicioLote.enEjecucion &&
            context.read<DependenciasEjecucion>().compartirUbicacion) ...[
          const SizedBox(height: EspaciadoCampo.l),
          const _TarjetaUbicacion(),
        ],
        const SizedBox(height: EspaciadoCampo.l),
        _Contacto(servicio: s),
        const SizedBox(height: EspaciadoCampo.l),
        _Datos(servicio: s),
      ],
    );
    // La acción principal queda anclada abajo, visible sin desplazarse: con
    // guantes y al sol no se busca el botón.
    final principal = _accionPrincipal(context, s, estado.ocupado);
    if (principal == null) return lista;
    return Column(
      children: [
        Expanded(child: lista),
        Material(
          color: paleta.fondo,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.m),
              child: principal,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avance extends StatelessWidget {
  const _Avance({required this.servicio});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.proveedorEjecucionAvance, style: texto.titleMedium),
          const SizedBox(height: EspaciadoCampo.s),
          Semantics(
            label: l10n.proveedorEjecucionAvancePorCiento(
              (s.porcentaje ?? 0).toString(),
            ),
            child: BarraProgresoCampo(fraccion: s.progreso),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            s.hectareasEjecutadas == null
                ? l10n.proveedorEjecucionTodaviaMarcasteAvance
                : '${FormatoMarketplace.hectareas(s.hectareasEjecutadas!)} de '
                      '${FormatoMarketplace.hectareas(s.hectareas)} · '
                      '${FormatoMarketplace.numero(s.porcentaje ?? Decimal.zero, decimales: 0)} %',
            style: texto.bodyLarge,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            s.fotosTotal == 0
                ? l10n.proveedorEjecucionSinFotosAvance
                : s.fotosTotal == 1
                ? l10n.proveedorEjecucionFotoAvance
                : l10n.proveedorEjecucionFotosAvance(s.fotosTotal),
            style: texto.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// La única acción principal de la pantalla, según el estado del servicio.
Widget? _accionPrincipal(BuildContext context, ServicioEnLote s, bool ocupado) {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<ServicioLoteCubit>();
  return switch (s.estado) {
    EstadoServicioLote.adjudicada => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonPrincipalMarketplace(
          texto: l10n.proveedorEjecucionMarcarEjecucion,
          icono: Icons.flight_takeoff_rounded,
          cargando: ocupado,
          onPressed: cubit.iniciarServicio,
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(
          l10n.proveedorEjecucionMarcaloCuandoEmpiecesLote,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
    EstadoServicioLote.enEjecucion => BotonPrincipalMarketplace(
      texto: l10n.proveedorEjecucionSubirFotoAvance,
      icono: Icons.photo_camera_rounded,
      cargando: ocupado,
      onPressed: cubit.tomarFotoDeAvance,
    ),
    EstadoServicioLote.finalizada => null,
  };
}

/// Marcar el avance y finalizar: importantes, pero no la acción principal.
class _AccionesSecundarias extends StatelessWidget {
  const _AccionesSecundarias({required this.servicio, required this.ocupado});

  final ServicioEnLote servicio;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final grande = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          style: grande,
          onPressed: ocupado ? null : () => _marcarAvance(context, s),
          child: Text(l10n.proveedorEjecucionMarcarAvance),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        OutlinedButton(
          style: grande,
          onPressed: ocupado ? null : () => _finalizar(context, s),
          child: Text(l10n.proveedorEjecucionFinalizarServicio),
        ),
      ],
    );
  }

  Future<void> _marcarAvance(BuildContext context, ServicioEnLote s) async {
    final cubit = context.read<ServicioLoteCubit>();
    final r = await showModalBottomSheet<_AvanceEscrito>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaAvance(servicio: s),
    );
    if (r == null) return;
    await cubit.marcarAvance(
      hectareas: r.enHectareas ? r.valor : null,
      porcentaje: r.enHectareas ? null : r.valor,
      nota: r.nota,
      motivoCorreccion: r.motivoCorreccion,
    );
  }

  Future<void> _finalizar(BuildContext context, ServicioEnLote s) async {
    final cubit = context.read<ServicioLoteCubit>();
    final r = await showModalBottomSheet<Decimal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaFinalizar(servicio: s),
    );
    if (r != null) await cubit.finalizar(hectareasEjecutadas: r);
  }
}

class _AvanceEscrito {
  const _AvanceEscrito(
    this.enHectareas,
    this.valor, {
    this.nota,
    this.motivoCorreccion,
  });

  final bool enHectareas;
  final Decimal valor;
  final String? nota;
  final String? motivoCorreccion;
}

class _HojaAvance extends StatefulWidget {
  const _HojaAvance({required this.servicio});

  final ServicioEnLote servicio;

  @override
  State<_HojaAvance> createState() => _HojaAvanceState();
}

class _HojaAvanceState extends State<_HojaAvance> {
  final _clave = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _nota = TextEditingController();
  final _motivo = TextEditingController();
  bool _enHectareas = true;

  @override
  void dispose() {
    _valor.dispose();
    _nota.dispose();
    _motivo.dispose();
    super.dispose();
  }

  /// El valor escrito baja respecto del último avance: el servidor exige un
  /// motivo de corrección.
  bool get _esCorreccion {
    final v = leerPrecio(_valor.text);
    if (v == null) return false;
    final s = widget.servicio;
    final previo = _enHectareas ? s.hectareasEjecutadas : s.porcentaje;
    return previo != null && v < previo;
  }

  String? _validar(String? t) {
    final l10n = AppLocalizations.of(context);
    final v = leerPrecio(t ?? '');
    if (v == null) return l10n.proveedorEjecucionEscribeNumeroMayorCero;
    final tope = _enHectareas
        ? widget.servicio.hectareas
        : Decimal.fromInt(100);
    if (v > tope) {
      return _enHectareas
          ? l10n.proveedorEjecucionPuedePasarLasHectareas
          : l10n.proveedorEjecucionPuedePasar100;
    }
    return null;
  }

  void _guardar() {
    if (!(_clave.currentState?.validate() ?? false)) return;
    final nota = _nota.text.trim();
    final motivo = _motivo.text.trim();
    if (_esCorreccion && motivo.isEmpty) {
      setState(() {});
      return;
    }
    Navigator.pop(
      context,
      _AvanceEscrito(
        _enHectareas,
        leerPrecio(_valor.text)!,
        nota: nota.isEmpty ? null : nota,
        motivoCorreccion: _esCorreccion ? motivo : null,
      ),
    );
  }

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
        child: Form(
          key: _clave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.proveedorEjecucionMarcarAvance,
                style: texto.titleLarge,
              ),
              const SizedBox(height: EspaciadoCampo.m),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.proveedorEjecucionHectareas),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.proveedorEjecucionPorcentaje),
                  ),
                ],
                selected: {_enHectareas},
                onSelectionChanged: (v) => setState(() {
                  _enHectareas = v.first;
                  _valor.clear();
                }),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              CampoFormularioMarketplace(
                etiqueta: _enHectareas
                    ? l10n.proveedorEjecucionHectareasEjecutadasTotal
                    : l10n.proveedorEjecucionPorcentajeEjecutadoTotal,
                controller: _valor,
                validator: _validar,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              if (_esCorreccion) ...[
                AvisoMarketplace(
                  mensaje: l10n.proveedorEjecucionMenosQueUltimoAvance,
                  tono: TonoAviso.alerta,
                ),
                const SizedBox(height: EspaciadoCampo.m),
                CampoFormularioMarketplace(
                  etiqueta: l10n.proveedorEjecucionMotivoCorreccion,
                  controller: _motivo,
                  errorServidor: _motivo.text.trim().isEmpty
                      ? l10n.proveedorEjecucionMotivoObligatorio
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              CampoFormularioMarketplace(
                etiqueta: l10n.proveedorEjecucionNotaOpcional,
                controller: _nota,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              BotonPrincipalMarketplace(
                texto: l10n.proveedorEjecucionGuardarAvance,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HojaFinalizar extends StatefulWidget {
  const _HojaFinalizar({required this.servicio});

  final ServicioEnLote servicio;

  @override
  State<_HojaFinalizar> createState() => _HojaFinalizarState();
}

class _HojaFinalizarState extends State<_HojaFinalizar> {
  final _clave = GlobalKey<FormState>();
  late final _ha = TextEditingController(
    text: (widget.servicio.hectareasEjecutadas ?? widget.servicio.hectareas)
        .toString(),
  );

  @override
  void dispose() {
    _ha.dispose();
    super.dispose();
  }

  String? _validar(String? t) {
    final l10n = AppLocalizations.of(context);
    final v = leerPrecio(t ?? '');
    if (v == null) return l10n.proveedorEjecucionEscribeLasHectareasRealmente;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.servicio;
    final texto = Theme.of(context).textTheme;
    final ha = leerPrecio(_ha.text);
    final monto = ha == null || s.precioHaAcordado == null
        ? null
        : ha * s.precioHaAcordado!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          0,
          EspaciadoCampo.l,
          EspaciadoCampo.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _clave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.proveedorEjecucionFinalizarServicio2,
                style: texto.titleLarge,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                l10n.proveedorEjecucionConfirmaLasHectareasQue,
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspaciadoCampo.m),
              CampoFormularioMarketplace(
                etiqueta: l10n.proveedorEjecucionHectareasEjecutadas,
                controller: _ha,
                validator: _validar,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              if (monto != null) ...[
                const SizedBox(height: EspaciadoCampo.s),
                Text(
                  l10n.proveedorEjecucionPagar(
                    FormatoMarketplace.bs(monto),
                    FormatoMarketplace.hectareas(ha!),
                    FormatoMarketplace.bs(s.precioHaAcordado!),
                  ),
                  style: texto.titleMedium,
                ),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              BotonPrincipalMarketplace(
                texto: l10n.proveedorEjecucionFinalizar,
                onPressed: () {
                  if (_clave.currentState?.validate() ?? false) {
                    Navigator.pop(context, leerPrecio(_ha.text));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrecioFinal extends StatelessWidget {
  const _PrecioFinal({required this.servicio});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final monto = s.montoAPagar;
    return SuperficieMarketplace(
      resaltada: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.montoConfirmado
                ? l10n.proveedorEjecucionPrecioFinalPagar
                : l10n.proveedorEjecucionPrecioEstimado,
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            monto == null
                ? l10n.proveedorEjecucionCalculando
                : FormatoMarketplace.bs(monto),
            style: texto.headlineMedium,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            s.hectareasEjecutadas == null || s.precioHaAcordado == null
                ? l10n.proveedorEjecucionHectareasEjecutadasPorPrecio
                : '${FormatoMarketplace.hectareas(s.hectareasEjecutadas!)} × '
                      '${FormatoMarketplace.bs(s.precioHaAcordado!)} por ha',
            style: texto.bodyLarge,
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            s.montoConfirmado
                ? l10n.proveedorEjecucionClientePagaDirectamenteApp
                : l10n.proveedorEjecucionUnaEstimacionHechaEste,
            style: texto.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TarjetaUbicacion extends StatelessWidget {
  const _TarjetaUbicacion();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<UbicacionCubit, UbicacionEstado>(
      builder: (context, u) {
        final cubit = context.read<UbicacionCubit>();
        final (titulo, detalle, boton) = switch (u.fase) {
          FaseUbicacion.compartiendo => (
            l10n.proveedorEjecucionCompartiendoUbicacion,
            u.sinRed
                ? l10n.proveedorEjecucionSinSenalReanudaSola
                : l10n.proveedorEjecucionClienteUltimaPosicionMapa,
            null,
          ),
          FaseUbicacion.denegadaParaSiempre => (
            l10n.proveedorEjecucionUbicacionBloqueada,
            l10n.proveedorEjecucionActivalaDesdeLosAjustes,
            null,
          ),
          FaseUbicacion.servicioApagado => (
            l10n.proveedorEjecucionUbicacionDelTelefonoEsta,
            l10n.proveedorEjecucionEnciendelaParaQueCliente,
            null,
          ),
          FaseUbicacion.denegada || FaseUbicacion.sinPedir => (
            l10n.proveedorEjecucionDileClienteDondeEstas,
            l10n.proveedorEjecucionAceptasCompartimosUltimaPosicion,
            l10n.proveedorEjecucionCompartirUbicacion,
          ),
        };
        return SuperficieMarketplace(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    u.fase == FaseUbicacion.compartiendo
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: context.paleta.acentoTexto,
                  ),
                  const SizedBox(width: EspaciadoCampo.s),
                  Expanded(child: Text(titulo, style: texto.titleMedium)),
                ],
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(detalle, style: texto.bodyMedium),
              if (u.ultimaEn != null)
                Padding(
                  padding: const EdgeInsets.only(top: EspaciadoCampo.xs),
                  child: Text(
                    l10n.proveedorEjecucionUltimaVez(
                      FormatoMarketplace.hora(u.ultimaEn!),
                    ),
                    style: texto.bodyMedium,
                  ),
                ),
              if (boton != null) ...[
                const SizedBox(height: EspaciadoCampo.m),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  onPressed: cubit.compartir,
                  child: Text(boton),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Contacto extends StatelessWidget {
  const _Contacto({required this.servicio});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    if (s.contactoNombre == null) return const SizedBox.shrink();
    final texto = Theme.of(context).textTheme;
    final t = AppLocalizations.of(context);
    final puesto = [?s.contactoCargo, ?s.contactoEmpresa].join(' · ');
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.contactoPilotoTitulo, style: texto.bodyMedium),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(s.contactoNombre!, style: texto.titleMedium),
          if (puesto.isNotEmpty)
            Text(
              puesto,
              key: const Key('contacto-cargo-empresa'),
              style: texto.bodyMedium,
            ),
          if (s.contactoTelefono != null)
            Text(s.contactoTelefono!, style: texto.bodyLarge),
        ],
      ),
    );
  }
}

class _Datos extends StatelessWidget {
  const _Datos({required this.servicio});

  final ServicioEnLote servicio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final filas = <(String, String)>[
      if (s.precioHaAcordado != null)
        (
          l10n.proveedorEjecucionPrecioAcordado,
          l10n.proveedorEjecucionPor(
            FormatoMarketplace.bs(s.precioHaAcordado!),
          ),
        ),
      if (s.ventanaDesde != null && s.ventanaHasta != null)
        (
          l10n.proveedorEjecucionFecha,
          l10n.proveedorEjecucionAl(
            FormatoMarketplace.fechaCorta(s.ventanaDesde!),
            FormatoMarketplace.fechaCorta(s.ventanaHasta!),
          ),
        ),
      if (s.producto != null && s.producto!.isNotEmpty)
        (l10n.proveedorEjecucionProducto, s.producto!),
      if (s.aportaProducto != null)
        (
          l10n.proveedorEjecucionPoneProducto,
          s.aportaProducto == 'cliente'
              ? l10n.proveedorEjecucionCliente
              : l10n.proveedorEjecucionTu,
        ),
      (
        l10n.proveedorEjecucionEstadoDelTerreno,
        s.accesoDificil
            ? l10n.proveedorEjecucionAccesoDificil
            : l10n.proveedorEjecucionAccesoNormal,
      ),
      if (s.referenciasAcceso != null)
        (l10n.proveedorEjecucionComoLlegar, s.referenciasAcceso!),
      if (s.colindantesSensibles != null)
        (l10n.proveedorEjecucionCuidar, s.colindantesSensibles!),
      if (s.observaciones != null)
        (l10n.proveedorEjecucionObservaciones, s.observaciones!),
    ];
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const Divider(height: EspaciadoCampo.xl),
            Text(
              filas[i].$1,
              style: texto.bodyMedium?.copyWith(
                color: context.paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: 2),
            Text(filas[i].$2, style: texto.bodyLarge),
          ],
        ],
      ),
    );
  }
}
