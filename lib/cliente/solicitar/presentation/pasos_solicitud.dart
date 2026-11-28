import '../../../nucleo/marketplace/precio/presentation/campo_justificacion_precio.dart';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/terrenos/presentation/galeria_fotos_terreno.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import 'opcion_solicitud.dart';
import 'solicitar_cubit.dart';
import 'solicitar_estado.dart';
import 'textos_errores_solicitud.dart';

const _margen = EdgeInsets.fromLTRB(
  EspaciadoCampo.l,
  EspaciadoCampo.l,
  EspaciadoCampo.l,
  EspaciadoCampo.xl,
);

/// Con el texto muy ampliado, etiqueta y valor no entran lado a lado.
bool _textoAmpliado(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 13;

class _Pregunta extends StatelessWidget {
  const _Pregunta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texto,
      style: TipografiaCampo.tituloBloque.copyWith(color: context.paleta.texto),
    ),
  );
}

// ── Paso 1: lote ───────────────────────────────────────────────────────

/// Lo que acompaña al mapa en el paso «Lote»: elegir un lote guardado o
/// seguir la guía para dibujar el contorno.
class PanelLote extends StatelessWidget {
  const PanelLote({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SolicitarCubit>();
    final guardado = estado.modoLote == ModoLote.guardado;
    return ListView(
      padding: _margen,
      children: [
        _Pregunta(l10n.solicitarQueLoteFumigamos),
        const SizedBox(height: EspaciadoCampo.m),
        _SelectorModo(modo: estado.modoLote, alCambiar: cubit.cambiarModoLote),
        const SizedBox(height: EspaciadoCampo.m),
        if (!guardado)
          _GuiaDibujo(estado: estado)
        else if (estado.lotes.isEmpty)
          EstadoVacioMarketplace(
            icono: Icons.landscape_outlined,
            titulo: l10n.solicitarTodaviaTienesLotesGuardados,
            detalle: l10n.solicitarPasaDibujarMarcaLas,
          )
        else
          for (final lote in estado.lotes) ...[
            _TarjetaLote(
              lote: lote,
              elegido: lote.id == estado.loteGuardado?.id,
              alTocar: () {
                HapticaCampo.seleccion();
                cubit.elegirLote(lote);
              },
            ),
            const SizedBox(height: EspaciadoCampo.s),
          ],
        if (estado.lote != null) ...[
          const SizedBox(height: EspaciadoCampo.l),
          const GaleriaFotosTerreno(),
        ],
      ],
    );
  }
}

class _SelectorModo extends StatelessWidget {
  const _SelectorModo({required this.modo, required this.alCambiar});

  final ModoLote modo;
  final ValueChanged<ModoLote> alCambiar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    Widget segmento(ModoLote valor, String etiqueta, IconData icono) {
      final activo = valor == modo;
      return Expanded(
        child: Semantics(
          button: true,
          selected: activo,
          inMutuallyExclusiveGroup: true,
          child: AnimatedContainer(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.minimo,
            ),
            decoration: BoxDecoration(
              color: activo ? paleta.superficie : Colors.transparent,
              borderRadius: BorderRadius.circular(RadioCampo.chip),
              border: Border.all(
                color: activo ? paleta.acentoTexto : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: ValueKey('modo-${valor.name}'),
                borderRadius: BorderRadius.circular(RadioCampo.chip),
                onTap: () {
                  if (!activo) HapticaCampo.seleccion();
                  alCambiar(valor);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspaciadoCampo.s,
                    vertical: EspaciadoCampo.s,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icono,
                        size: 20,
                        color: activo
                            ? paleta.acentoTexto
                            : paleta.textoSecundario,
                      ),
                      const SizedBox(width: EspaciadoCampo.s),
                      Flexible(
                        child: Text(
                          etiqueta,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: activo
                                    ? paleta.texto
                                    : paleta.textoSecundario,
                              ),
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

    return Container(
      padding: const EdgeInsets.all(EspaciadoCampo.xs),
      decoration: BoxDecoration(
        color: paleta.superficie2,
        borderRadius: BorderRadius.circular(radioOpcion),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            segmento(
              ModoLote.guardado,
              l10n.solicitarMisLotes,
              Icons.layers_outlined,
            ),
            const SizedBox(width: EspaciadoCampo.xs),
            segmento(
              ModoLote.dibujo,
              l10n.solicitarDibujar,
              Icons.draw_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaLote extends StatelessWidget {
  const _TarjetaLote({
    required this.lote,
    required this.elegido,
    required this.alTocar,
  });

  final Lote lote;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      selected: elegido,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: SuperficieMarketplace(
        resaltada: elegido,
        onTap: alTocar,
        child: Row(
          children: [
            Icon(
              elegido
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: elegido ? paleta.acentoTexto : paleta.bordeFuerte,
            ),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lote.nombre, style: texto.titleMedium),
                  Text(
                    '${lote.zona} · ${lote.cultivo} · '
                    '${FormatoMarketplace.hectareas(lote.hectareas)}',
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuiaDibujo extends StatelessWidget {
  const _GuiaDibujo({required this.estado});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SolicitarCubit>();
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final marcadas = estado.vertices.length;
    final (icono, mensaje) = switch (marcadas) {
      0 => (Icons.touch_app_outlined, l10n.solicitarTocaMapaCadaEsquina),
      1 => (Icons.touch_app_outlined, l10n.solicitarBienMarcaDosEsquinas),
      2 => (Icons.touch_app_outlined, l10n.solicitarFaltaUnaEsquinaPara),
      _ => (Icons.open_with_rounded, l10n.solicitarContornoListoArrastraUna),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: paleta.acentoTexto),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Text(
                  mensaje,
                  style: texto.bodyMedium?.copyWith(color: paleta.texto),
                ),
              ),
            ],
          ),
        ),
        if (marcadas > 0) ...[
          const SizedBox(height: EspaciadoCampo.l),
          Wrap(
            spacing: EspaciadoCampo.s,
            runSpacing: EspaciadoCampo.s,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('dibujo-deshacer'),
                onPressed: cubit.deshacerVertice,
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.solicitarDeshacer),
              ),
              TextButton.icon(
                key: const ValueKey('dibujo-borrar'),
                onPressed: cubit.borrarContorno,
                style: TextButton.styleFrom(
                  foregroundColor: paleta.texto,
                  minimumSize: const Size(64, ObjetivoTactilCampo.minimo),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.solicitarBorrarTodo),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Paso 2: aplicación ─────────────────────────────────────────────────

/// Hectáreas, cultivo y producto.
class PasoAplicacion extends StatefulWidget {
  const PasoAplicacion({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  State<PasoAplicacion> createState() => _PasoAplicacionState();
}

class _PasoAplicacionState extends State<PasoAplicacion> {
  late final _hectareas = TextEditingController(
    text: widget.estado.hectareasTexto,
  );

  @override
  void dispose() {
    _hectareas.dispose();
    super.dispose();
  }

  OutlineInputBorder _borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioOpcion),
        borderSide: BorderSide(color: color, width: ancho),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SolicitarCubit>();
    final e = widget.estado;
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final calculadas = e.hectareasCalculadas;
    final cultivos = {
      if (e.cultivo != null && e.cultivo!.isNotEmpty) e.cultivo!,
      ...e.cultivos,
    };
    return ListView(
      padding: _margen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Pregunta(l10n.solicitarQueVamosAplicar),
        TituloGrupoSolicitud(l10n.solicitarHectareasFumigar),
        Semantics(
          label: l10n.solicitarHectareasFumigar,
          child: TextField(
            key: const ValueKey('solicitar-hectareas'),
            controller: _hectareas,
            onChanged: cubit.cambiarHectareas,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(8),
            ],
            style: TipografiaCampo.cifraGrande.copyWith(color: paleta.texto),
            cursorColor: paleta.acentoTexto,
            decoration: InputDecoration(
              filled: true,
              fillColor: paleta.superficie,
              hintText: '0',
              hintStyle: TipografiaCampo.cifraGrande.copyWith(
                color: paleta.bordeFuerte,
              ),
              suffixText: l10n.solicitarHa,
              suffixStyle: texto.titleLarge?.copyWith(
                color: paleta.textoSecundario,
              ),
              helperText: calculadas == null
                  ? null
                  : e.modoLote == ModoLote.dibujo
                  ? l10n.solicitarHectareasDelContorno(
                      FormatoMarketplace.hectareas(calculadas),
                    )
                  : l10n.solicitarHectareasDelLote(
                      FormatoMarketplace.hectareas(calculadas),
                    ),
              helperMaxLines: 4,
              helperStyle: texto.bodySmall?.copyWith(
                color: paleta.textoSecundario,
              ),
              errorText: e.errorHectareas?.texto(
                l10n,
                tope: e.loteGuardado?.hectareas.toString() ?? '',
              ),
              errorMaxLines: 4,
              errorStyle: texto.bodySmall?.copyWith(color: paleta.error),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.m,
              ),
              enabledBorder: _borde(paleta.bordeFuerte),
              focusedBorder: _borde(paleta.acentoTexto, 2),
              errorBorder: _borde(paleta.error),
              focusedErrorBorder: _borde(paleta.error, 2),
            ),
          ),
        ),
        TituloGrupoSolicitud(l10n.solicitarCultivo),
        Wrap(
          spacing: EspaciadoCampo.s,
          runSpacing: EspaciadoCampo.s,
          children: [
            for (final c in cultivos)
              OpcionSolicitud(
                titulo: c,
                elegida: c == e.cultivo,
                alElegir: () => cubit.elegirCultivo(c),
              ),
          ],
        ),
        TituloGrupoSolicitud(l10n.solicitarProducto),
        Wrap(
          spacing: EspaciadoCampo.s,
          runSpacing: EspaciadoCampo.s,
          children: [
            for (final p in e.productos)
              OpcionSolicitud(
                titulo: p,
                elegida: p == e.producto,
                alElegir: () => cubit.elegirProducto(p),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Paso 3: cuándo ─────────────────────────────────────────────────────

/// Fecha deseada, accesos y observaciones: lo que un piloto necesita saber
/// antes de ofertar.
class PasoCuando extends StatefulWidget {
  const PasoCuando({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  State<PasoCuando> createState() => _PasoCuandoState();
}

class _PasoCuandoState extends State<PasoCuando> {
  late final _accesos = TextEditingController(text: widget.estado.accesos);
  late final _observaciones = TextEditingController(
    text: widget.estado.observaciones,
  );

  @override
  void dispose() {
    _accesos.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SolicitarCubit>();
    final estado = widget.estado;
    // Un terreno ya registrado trae sus accesos; solo uno nuevo los pide.
    final pideAccesos = estado.modoLote == ModoLote.dibujo;
    return ListView(
      padding: _margen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Pregunta(l10n.solicitarCuandoNecesitas),
        const SizedBox(height: EspaciadoCampo.l),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, dia) in estado.fechas.indexed) ...[
                  if (i > 0) const SizedBox(width: EspaciadoCampo.s),
                  _TarjetaFecha(
                    key: ValueKey('fecha-$i'),
                    fecha: dia,
                    elegida: dia == estado.fecha,
                    alElegir: () => cubit.elegirFecha(dia),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (estado.errorFecha != null) ...[
          const SizedBox(height: EspaciadoCampo.m),
          AvisoMarketplace(mensaje: estado.errorFecha!, tono: TonoAviso.error),
        ],
        if (cubit.fechaUrgente) ...[
          const SizedBox(height: EspaciadoCampo.m),
          AvisoMarketplace(mensaje: l10n.solicitarPedirloParaMananaMarca),
        ],
        if (estado.contactos.isNotEmpty) ...[
          TituloGrupoSolicitud(
            AppLocalizations.of(context).contactosEmpresaPublicar,
          ),
          Text(
            AppLocalizations.of(context).contactosEmpresaPublicarAyuda,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          RadioGroup<int>(
            groupValue: estado.contactoId,
            onChanged: (id) {
              if (id != null) cubit.elegirContacto(id);
            },
            child: Column(
              children: [
                for (final c in estado.contactos)
                  RadioListTile<int>(
                    key: ValueKey('solicitar-contacto-${c.id}'),
                    contentPadding: EdgeInsets.zero,
                    value: c.id,
                    title: Text(c.nombre),
                    subtitle: Text([?c.cargo, c.telefono].join(' · ')),
                  ),
              ],
            ),
          ),
        ],
        TituloGrupoSolicitud(l10n.solicitarDatosParaLosPilotos),
        if (pideAccesos) ...[
          TextField(
            key: const ValueKey('solicitar-accesos'),
            controller: _accesos,
            onChanged: cubit.cambiarAccesos,
            maxLength: 300,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.solicitarComoLlegaLoteOpcional,
              hintText: l10n.solicitarCaminoPortonReferencias,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.m),
        ],
        TextField(
          key: const ValueKey('solicitar-observaciones'),
          controller: _observaciones,
          onChanged: cubit.cambiarObservaciones,
          maxLength: 500,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.solicitarObservacionesOpcional,
            hintText: l10n.solicitarCultivosVecinosLineasElectricas,
          ),
        ),
      ],
    );
  }
}

class _TarjetaFecha extends StatelessWidget {
  const _TarjetaFecha({
    required this.fecha,
    required this.elegida,
    required this.alElegir,
    super.key,
  });

  final DateTime fecha;
  final bool elegida;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final forma = BorderRadius.circular(radioOpcion);
    final apoyo = texto.bodySmall?.copyWith(
      color: elegida ? paleta.texto : paleta.textoSecundario,
      fontWeight: elegida ? FontWeight.w700 : FontWeight.w500,
    );
    return Semantics(
      button: true,
      selected: elegida,
      inMutuallyExclusiveGroup: true,
      label: FormatoMarketplace.fechaConDia(fecha),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
        constraints: const BoxConstraints(minWidth: 64, minHeight: 80),
        decoration: BoxDecoration(
          color: elegida ? paleta.acentoContenedor : paleta.superficie,
          borderRadius: forma,
          border: Border.all(
            color: elegida ? paleta.acentoTexto : paleta.bordeFuerte,
            width: elegida ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: forma,
            onTap: () {
              if (!elegida) HapticaCampo.seleccion();
              alElegir();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.m,
                vertical: EspaciadoCampo.s,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(FormatoMarketplace.diaSemana(fecha), style: apoyo),
                  Text('${fecha.day}', style: texto.headlineSmall),
                  Text(
                    FormatoMarketplace.fechaCorta(fecha).split(' ').last,
                    style: apoyo,
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

// ── Paso 4: precio ─────────────────────────────────────────────────────

/// El precio por hectárea que propone el cliente, con el total estimado y un
/// resumen de lo que se va a publicar. El precio no es una tarifa: los
/// pilotos aceptan o contraofertan.
class PasoPrecio extends StatefulWidget {
  const PasoPrecio({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  State<PasoPrecio> createState() => _PasoPrecioState();
}

class _PasoPrecioState extends State<PasoPrecio> {
  /// La parte entera del precio escrito, para el stepper de ±1 Bs.
  static int _precioEntero(Decimal? precio) =>
      precio == null ? 1 : precio.truncate().toBigInt().toInt().clamp(1, 99999);

  late final _precio = TextEditingController(text: widget.estado.precioTexto);
  late final _justificacion = TextEditingController(
    text: widget.estado.justificacion,
  );

  @override
  void dispose() {
    _precio.dispose();
    _justificacion.dispose();
    super.dispose();
  }

  OutlineInputBorder _borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioOpcion),
        borderSide: BorderSide(color: color, width: ancho),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SolicitarCubit>();
    final e = widget.estado;
    final lote = e.lote;
    final hectareas = e.hectareas;
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    if (lote == null || hectareas == null) return const SizedBox.shrink();
    final total = e.total;

    return ListView(
      padding: _margen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Pregunta(l10n.solicitarCuantoPagasPorHectarea),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          l10n.solicitarLosPilotosPuedenAceptar,
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        // Con ±1 se ajusta de a un boliviano; el campo de abajo admite el
        // precio exacto (con decimales) y es el que valida el cubit.
        SuperficieMarketplace(
          child: Center(
            child: StepperCampo(
              valor: _precioEntero(e.precio),
              etiqueta: l10n.solicitarPrecioPorHectarea,
              unidad: 'Bs/ha',
              minimo: 1,
              maximo: 99999,
              onCambio: (v) {
                final escrito = '$v';
                _precio.value = TextEditingValue(
                  text: escrito,
                  selection: TextSelection.collapsed(offset: escrito.length),
                );
                cubit.cambiarPrecio(escrito);
              },
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Semantics(
          label: l10n.solicitarPrecioExactoPorHectarea,
          child: TextField(
            key: const ValueKey('solicitar-precio'),
            controller: _precio,
            onChanged: cubit.cambiarPrecio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(8),
            ],
            style: TipografiaCampo.cifraMedia.copyWith(color: paleta.texto),
            cursorColor: paleta.acentoTexto,
            decoration: InputDecoration(
              filled: true,
              fillColor: paleta.superficie,
              hintText: '0',
              hintStyle: TipografiaCampo.cifraMedia.copyWith(
                color: paleta.bordeFuerte,
              ),
              labelText: l10n.solicitarPrecioExacto,
              prefixText: l10n.solicitarBs,
              prefixStyle: TipografiaCampo.cifraMedia.copyWith(
                color: paleta.textoSecundario,
              ),
              suffixText: l10n.solicitarPor,
              suffixStyle: texto.titleMedium?.copyWith(
                color: paleta.textoSecundario,
              ),
              errorText: e.errorPrecio?.texto(l10n),
              errorMaxLines: 3,
              errorStyle: texto.bodySmall?.copyWith(color: paleta.error),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.m,
              ),
              enabledBorder: _borde(paleta.bordeFuerte),
              focusedBorder: _borde(paleta.acentoTexto, 2),
              errorBorder: _borde(paleta.error),
              focusedErrorBorder: _borde(paleta.error, 2),
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        SuperficieMarketplace(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.solicitarTotalEstimado,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: total == null
                    ? Text(
                        l10n.solicitarBs2,
                        key: const ValueKey('resumen-precio'),
                        style: TipografiaCampo.cifraGrande.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      )
                    : CifraCampo(
                        key: const ValueKey('resumen-precio'),
                        valor: FormatoMarketplace.bsNumero(total),
                        unidad: 'Bs',
                        estilo: TipografiaCampo.cifraGrande,
                      ),
              ),
              Text(
                total == null
                    ? l10n.solicitarEscribePrecioParaVer
                    : l10n.solicitarHa2(
                        FormatoMarketplace.bs(e.precio!),
                        FormatoMarketplace.hectareas(hectareas),
                      ),
                style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
              ),
              Divider(height: EspaciadoCampo.xl, color: paleta.borde),
              Text(
                l10n.solicitarPrecioFinalCalculaCon,
                style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        CampoJustificacionPrecio(
          controller: _justificacion,
          onChanged: cubit.cambiarJustificacion,
        ),
        const SizedBox(height: EspaciadoCampo.l),
        SuperficieMarketplace(
          child: Column(
            children: [
              _FilaResumen(l10n.solicitarLote, '${lote.nombre}, ${lote.zona}'),
              _FilaResumen(
                l10n.solicitarSuperficie2,
                FormatoMarketplace.hectareas(hectareas),
              ),
              _FilaResumen(l10n.solicitarCultivo, e.cultivo ?? ''),
              _FilaResumen(l10n.solicitarProducto, e.producto ?? ''),
              if (e.fecha != null)
                _FilaResumen(
                  l10n.solicitarFecha,
                  FormatoMarketplace.fechaConDia(e.fecha!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final nombre = Text(
      etiqueta,
      style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
    );
    final dato = Text(
      valor,
      textAlign: _textoAmpliado(context) ? TextAlign.start : TextAlign.end,
      style: texto.bodyMedium?.copyWith(
        color: paleta.texto,
        fontWeight: FontWeight.w800,
      ),
    );
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.xs),
        child: _textoAmpliado(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [nombre, dato],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: nombre,
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(child: dato),
                ],
              ),
      ),
    );
  }
}
