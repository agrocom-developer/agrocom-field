import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            title: Text(s?.terreno?.nombre ?? 'Servicio'),
            actions: [
              if (s != null && s.estado != EstadoServicioLote.finalizada)
                IconButton(
                  tooltip: 'Chat con el cliente',
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
              ? const EstadoVacioMarketplace(
                  icono: Icons.search_off_rounded,
                  titulo: 'No encontramos este servicio',
                  detalle:
                      'Puede que el cliente lo haya cancelado. Vuelve a la '
                      'lista y actualiza.',
                )
              : _Contenido(servicio: s, estado: estado),
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
                ? 'El servidor no aceptó algo de lo que guardaste. Avisa a '
                      'soporte desde el perfil.'
                : 'Está guardado en este celular y se sube solo cuando '
                      'vuelva la señal.',
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
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avance', style: texto.titleMedium),
          const SizedBox(height: EspaciadoCampo.s),
          Semantics(
            label: 'Avance ${s.porcentaje ?? 0} por ciento',
            child: BarraProgresoCampo(fraccion: s.progreso),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            s.hectareasEjecutadas == null
                ? 'Todavía no marcaste avance.'
                : '${FormatoMarketplace.hectareas(s.hectareasEjecutadas!)} de '
                      '${FormatoMarketplace.hectareas(s.hectareas)} · '
                      '${FormatoMarketplace.numero(s.porcentaje ?? Decimal.zero, decimales: 0)} %',
            style: texto.bodyLarge,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            s.fotosTotal == 0
                ? 'Sin fotos de avance'
                : s.fotosTotal == 1
                ? '1 foto de avance'
                : '${s.fotosTotal} fotos de avance',
            style: texto.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// La única acción principal de la pantalla, según el estado del servicio.
Widget? _accionPrincipal(BuildContext context, ServicioEnLote s, bool ocupado) {
  final cubit = context.read<ServicioLoteCubit>();
  return switch (s.estado) {
    EstadoServicioLote.adjudicada => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonPrincipalMarketplace(
          texto: 'Marcar en ejecución',
          icono: Icons.flight_takeoff_rounded,
          cargando: ocupado,
          onPressed: cubit.iniciarServicio,
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(
          'Márcalo cuando empieces en el lote. El cliente recibe el aviso.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
    EstadoServicioLote.enEjecucion => BotonPrincipalMarketplace(
      texto: 'Subir foto de avance',
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
          child: const Text('Marcar avance'),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        OutlinedButton(
          style: grande,
          onPressed: ocupado ? null : () => _finalizar(context, s),
          child: const Text('Finalizar servicio'),
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
    final v = leerPrecio(t ?? '');
    if (v == null) return 'Escribe un número mayor a cero.';
    final tope = _enHectareas
        ? widget.servicio.hectareas
        : Decimal.fromInt(100);
    if (v > tope) {
      return _enHectareas
          ? 'No puede pasar de las hectáreas del servicio.'
          : 'No puede pasar de 100 %.';
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
              Text('Marcar avance', style: texto.titleLarge),
              const SizedBox(height: EspaciadoCampo.m),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Hectáreas')),
                  ButtonSegment(value: false, label: Text('Porcentaje')),
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
                    ? 'Hectáreas ejecutadas en total'
                    : 'Porcentaje ejecutado en total',
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
                const AvisoMarketplace(
                  mensaje:
                      'Es menos que tu último avance. Cuéntanos por qué lo '
                      'corriges.',
                  tono: TonoAviso.alerta,
                ),
                const SizedBox(height: EspaciadoCampo.m),
                CampoFormularioMarketplace(
                  etiqueta: 'Motivo de la corrección',
                  controller: _motivo,
                  errorServidor: _motivo.text.trim().isEmpty
                      ? 'El motivo es obligatorio.'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              CampoFormularioMarketplace(
                etiqueta: 'Nota (opcional)',
                controller: _nota,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              BotonPrincipalMarketplace(
                texto: 'Guardar avance',
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
    final v = leerPrecio(t ?? '');
    if (v == null) return 'Escribe las hectáreas realmente ejecutadas.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Finalizar el servicio', style: texto.titleLarge),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                'Confirma las hectáreas que realmente ejecutaste. El precio '
                'final es hectáreas ejecutadas por el precio acordado.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspaciadoCampo.m),
              CampoFormularioMarketplace(
                etiqueta: 'Hectáreas ejecutadas',
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
                  'A pagar: ${FormatoMarketplace.bs(monto)} '
                  '(${FormatoMarketplace.hectareas(ha!)} × '
                  '${FormatoMarketplace.bs(s.precioHaAcordado!)})',
                  style: texto.titleMedium,
                ),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              BotonPrincipalMarketplace(
                texto: 'Finalizar',
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
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final monto = s.montoAPagar;
    return SuperficieMarketplace(
      resaltada: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.montoConfirmado ? 'Precio final a pagar' : 'Precio estimado',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            monto == null ? 'Calculando…' : FormatoMarketplace.bs(monto),
            style: texto.headlineMedium,
          ),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            s.hectareasEjecutadas == null || s.precioHaAcordado == null
                ? 'Hectáreas ejecutadas por el precio acordado.'
                : '${FormatoMarketplace.hectareas(s.hectareasEjecutadas!)} × '
                      '${FormatoMarketplace.bs(s.precioHaAcordado!)} por ha',
            style: texto.bodyLarge,
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            s.montoConfirmado
                ? 'El cliente te paga directamente: la app no cobra.'
                : 'Es una estimación hecha en este celular. El monto final lo '
                      'confirma el servidor cuando haya señal.',
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
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<UbicacionCubit, UbicacionEstado>(
      builder: (context, u) {
        final cubit = context.read<UbicacionCubit>();
        final (titulo, detalle, boton) = switch (u.fase) {
          FaseUbicacion.compartiendo => (
            'Compartiendo tu ubicación',
            u.sinRed
                ? 'Sin señal: se reanuda sola. Nada se guarda en el celular.'
                : 'El cliente ve tu última posición en un mapa mientras esta '
                      'pantalla esté abierta.',
            null,
          ),
          FaseUbicacion.denegadaParaSiempre => (
            'Ubicación bloqueada',
            'Actívala desde los ajustes del teléfono si quieres que el '
                'cliente vea dónde estás.',
            null,
          ),
          FaseUbicacion.servicioApagado => (
            'La ubicación del teléfono está apagada',
            'Enciéndela para que el cliente vea tu última posición.',
            null,
          ),
          FaseUbicacion.denegada || FaseUbicacion.sinPedir => (
            'Dile al cliente dónde estás',
            'Si lo aceptas, compartimos tu última posición con el cliente '
                'mientras el servicio esté en ejecución y esta pantalla '
                'abierta. Se deja de compartir al cerrarla o al finalizar. '
                'No guardamos tu recorrido.',
            'Compartir mi ubicación',
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
                    'Última vez ${FormatoMarketplace.hora(u.ultimaEn!)}',
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
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cliente', style: texto.bodyMedium),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(s.contactoNombre!, style: texto.titleMedium),
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
    final s = servicio;
    final texto = Theme.of(context).textTheme;
    final filas = <(String, String)>[
      if (s.precioHaAcordado != null)
        (
          'Precio acordado',
          '${FormatoMarketplace.bs(s.precioHaAcordado!)} por ha',
        ),
      if (s.ventanaDesde != null && s.ventanaHasta != null)
        (
          'Fecha',
          '${FormatoMarketplace.fechaCorta(s.ventanaDesde!)} al '
              '${FormatoMarketplace.fechaCorta(s.ventanaHasta!)}',
        ),
      if (s.producto != null && s.producto!.isNotEmpty)
        ('Producto', s.producto!),
      if (s.aportaProducto != null)
        (
          'Pone el producto',
          s.aportaProducto == 'cliente' ? 'El cliente' : 'Tú',
        ),
      (
        'Estado del terreno',
        s.accesoDificil ? 'Acceso difícil' : 'Acceso normal',
      ),
      if (s.referenciasAcceso != null) ('Cómo llegar', s.referenciasAcceso!),
      if (s.colindantesSensibles != null) ('Cuidar', s.colindantesSensibles!),
      if (s.observaciones != null) ('Observaciones', s.observaciones!),
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
