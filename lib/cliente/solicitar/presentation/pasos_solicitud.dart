import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import 'opcion_solicitud.dart';
import 'solicitar_cubit.dart';
import 'solicitar_estado.dart';

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
    child: Text(texto, style: Theme.of(context).textTheme.headlineSmall),
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
    final cubit = context.read<SolicitarCubit>();
    final guardado = estado.modoLote == ModoLote.guardado;
    return ListView(
      padding: _margen,
      children: [
        const _Pregunta('¿Qué lote fumigamos?'),
        const SizedBox(height: EspaciadoCampo.m),
        _SelectorModo(modo: estado.modoLote, alCambiar: cubit.cambiarModoLote),
        const SizedBox(height: EspaciadoCampo.m),
        if (!guardado)
          _GuiaDibujo(estado: estado)
        else if (estado.lotes.isEmpty)
          const EstadoVacioMarketplace(
            icono: Icons.landscape_outlined,
            titulo: 'Todavía no tienes lotes guardados',
            detalle: 'Pasa a «Dibujar» y marca las esquinas en el mapa.',
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
              color: activo
                  ? paleta.superficie
                  : paleta.superficie.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(radioOpcion - 4),
              border: Border.all(
                color: activo
                    ? paleta.acentoTexto
                    : paleta.acentoTexto.withValues(alpha: 0),
                width: 1.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: ValueKey('modo-${valor.name}'),
                borderRadius: BorderRadius.circular(radioOpcion - 4),
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
        color: paleta.texto.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radioOpcion),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            segmento(ModoLote.guardado, 'Mis lotes', Icons.layers_outlined),
            const SizedBox(width: EspaciadoCampo.xs),
            segmento(ModoLote.dibujo, 'Dibujar', Icons.draw_outlined),
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
    final cubit = context.read<SolicitarCubit>();
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final marcadas = estado.vertices.length;
    final (icono, mensaje) = switch (marcadas) {
      0 => (
        Icons.touch_app_outlined,
        'Toca el mapa en cada esquina del lote. Con tres esquinas ya se '
            'calcula la superficie.',
      ),
      1 => (Icons.touch_app_outlined, 'Bien. Marca dos esquinas más.'),
      2 => (Icons.touch_app_outlined, 'Falta una esquina para cerrar el lote.'),
      _ => (
        Icons.open_with_rounded,
        'Contorno listo. Arrastra una esquina para ajustarla o sigue '
            'agregando puntos.',
      ),
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
                label: const Text('Deshacer'),
              ),
              TextButton.icon(
                key: const ValueKey('dibujo-borrar'),
                onPressed: cubit.borrarContorno,
                style: TextButton.styleFrom(
                  foregroundColor: paleta.texto,
                  minimumSize: const Size(64, ObjetivoTactilCampo.minimo),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Borrar todo'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Paso 2: aplicación ─────────────────────────────────────────────────

/// Hectáreas, cultivo, producto y dosis.
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
    final cubit = context.read<SolicitarCubit>();
    final e = widget.estado;
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final calculadas = e.hectareasCalculadas;
    final cultivos = {
      if (e.cultivo != null && e.cultivo!.isNotEmpty) e.cultivo!,
      ...e.cultivos,
    };
    final litros = e.litrosTotales;

    return ListView(
      padding: _margen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const _Pregunta('¿Qué vamos a aplicar?'),
        const TituloGrupoSolicitud('Hectáreas a fumigar'),
        Semantics(
          label: 'Hectáreas a fumigar',
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
            style: texto.headlineSmall,
            cursorColor: paleta.acentoTexto,
            decoration: InputDecoration(
              filled: true,
              fillColor: paleta.superficie,
              hintText: '0',
              hintStyle: texto.headlineSmall?.copyWith(
                color: paleta.bordeFuerte,
              ),
              suffixText: 'ha',
              suffixStyle: texto.titleLarge?.copyWith(
                color: paleta.textoSecundario,
              ),
              helperText: calculadas == null
                  ? null
                  : '${e.modoLote == ModoLote.dibujo ? 'Del contorno salen' : 'El lote tiene'} '
                        '${FormatoMarketplace.hectareas(calculadas)}. '
                        'Ajustalas si vas a fumigar otra superficie.',
              helperMaxLines: 4,
              helperStyle: texto.bodySmall?.copyWith(
                color: paleta.textoSecundario,
              ),
              errorText: e.errorHectareas,
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
        const TituloGrupoSolicitud('Cultivo'),
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
        const TituloGrupoSolicitud('Producto'),
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
        const TituloGrupoSolicitud('Dosis por hectárea'),
        SuperficieMarketplace(
          padding: const EdgeInsets.all(EspaciadoCampo.s),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Bajar la dosis',
                onPressed: cubit.bajarDosis,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${FormatoMarketplace.numero(e.dosisEfectiva, decimales: 1)} L/ha',
                      style: texto.headlineSmall,
                    ),
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Subir la dosis',
                onPressed: cubit.subirDosis,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        if (litros != null) ...[
          const SizedBox(height: EspaciadoCampo.m),
          Text(
            'Caldo total: ${FormatoMarketplace.litros(litros)}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ],
    );
  }
}

// ── Paso 3: cuándo ─────────────────────────────────────────────────────

/// Fecha deseada y ventana horaria.
class PasoCuando extends StatelessWidget {
  const PasoCuando({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SolicitarCubit>();
    return ListView(
      padding: _margen,
      children: [
        const _Pregunta('¿Cuándo lo necesitas?'),
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
          const AvisoMarketplace(
            mensaje:
                'Pedirlo para mañana lleva un recargo por urgencia. Lo ves '
                'detallado en el resumen antes de confirmar.',
          ),
        ],
        const TituloGrupoSolicitud('Horario preferido'),
        for (final v in VentanaHoraria.values) ...[
          OpcionSolicitud(
            key: ValueKey('ventana-${v.name}'),
            titulo: v == VentanaHoraria.indistinta
                ? v.etiqueta
                : '${v.etiqueta} · ${v.horario}',
            apoyo: v.apoyo,
            elegida: v == estado.ventana,
            alElegir: () => cubit.elegirVentana(v),
          ),
          const SizedBox(height: EspaciadoCampo.s),
        ],
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
          color: elegida
              ? Color.alphaBlend(
                  paleta.acento.withValues(alpha: 0.16),
                  paleta.superficie,
                )
              : paleta.superficie,
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

// ── Paso 4: resumen ────────────────────────────────────────────────────

/// Todo lo que se va a pedir, de un vistazo: la superficie como dato
/// protagonista, el detalle y el precio estimado con sus recargos.
class PasoResumen extends StatelessWidget {
  const PasoResumen({required this.estado, super.key});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SolicitarCubit>();
    final e = estado;
    final lote = e.lote;
    final hectareas = e.hectareas;
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    if (lote == null || hectareas == null) return const SizedBox.shrink();
    final litros = e.litrosTotales;

    return ListView(
      padding: _margen,
      children: [
        const _Pregunta('Revisa tu solicitud'),
        if (e.falloEnvio != null) ...[
          const SizedBox(height: EspaciadoCampo.m),
          Semantics(
            liveRegion: true,
            child: switch (e.falloEnvio!) {
              FalloEnvio.sinConexion => const AvisoMarketplace(
                key: ValueKey('aviso-sin-conexion'),
                tono: TonoAviso.alerta,
                icono: Icons.wifi_off_rounded,
                mensaje:
                    'Sin conexión. Tu solicitud sigue aquí, completa: cuando '
                    'vuelva la señal, reintenta el envío.',
              ),
              FalloEnvio.desconocido => const AvisoMarketplace(
                key: ValueKey('aviso-fallo-envio'),
                tono: TonoAviso.error,
                mensaje:
                    'No pudimos enviar la solicitud. Tus datos siguen aquí; '
                    'prueba de nuevo.',
              ),
            },
          ),
        ],
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          label:
              '${FormatoMarketplace.hectareas(hectareas)} de ${e.cultivo}, '
              '${lote.nombre}, ${lote.zona}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  FormatoMarketplace.hectareas(hectareas),
                  key: const ValueKey('resumen-hectareas'),
                  style: texto.displaySmall,
                ),
              ),
              Text(
                '${e.cultivo} · ${lote.nombre}, ${lote.zona}',
                style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        SuperficieMarketplace(
          child: Column(
            children: [
              _FilaResumen('Producto', e.producto ?? ''),
              _FilaResumen(
                'Dosis',
                '${FormatoMarketplace.numero(e.dosisEfectiva, decimales: 1)} L/ha',
              ),
              if (litros != null)
                _FilaResumen('Caldo total', FormatoMarketplace.litros(litros)),
              if (e.fecha != null)
                _FilaResumen('Fecha', FormatoMarketplace.fechaConDia(e.fecha!)),
              _FilaResumen(
                'Horario',
                e.ventana == VentanaHoraria.indistinta
                    ? e.ventana.etiqueta
                    : '${e.ventana.etiqueta}, ${e.ventana.horario}',
              ),
            ],
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          child: e.estimacion != null
              ? _Precio(
                  key: const ValueKey('precio'),
                  estimacion: e.estimacion!,
                  hectareas: FormatoMarketplace.hectareas(hectareas),
                )
              : e.falloEstimacion
              ? Column(
                  key: const ValueKey('precio-error'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AvisoMarketplace(
                      tono: TonoAviso.error,
                      mensaje:
                          'No pudimos calcular el precio estimado. Revisa tu '
                          'conexión.',
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    OutlinedButton.icon(
                      onPressed: cubit.estimar,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Calcular de nuevo'),
                    ),
                  ],
                )
              : const SuperficieMarketplace(
                  key: ValueKey('precio-cargando'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EsqueletoCampo(ancho: 120, alto: 14),
                      SizedBox(height: EspaciadoCampo.m),
                      EsqueletoCampo(ancho: 160, alto: 28),
                      SizedBox(height: EspaciadoCampo.m),
                      EsqueletoCampo(alto: 14),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Precio extends StatelessWidget {
  const _Precio({required this.estimacion, required this.hectareas, super.key});

  final EstimacionServicio estimacion;
  final String hectareas;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final e = estimacion;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precio estimado',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FormatoMarketplace.bs(e.precio),
              key: const ValueKey('resumen-precio'),
              style: texto.headlineSmall,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          _FilaResumen(
            '${FormatoMarketplace.bs(e.precioPorHectarea)}/ha × $hectareas',
            FormatoMarketplace.bs(e.subtotal),
            tenue: true,
          ),
          for (final r in e.recargos)
            _FilaResumen(
              r.concepto,
              FormatoMarketplace.bs(r.monto),
              tenue: true,
            ),
          Divider(height: EspaciadoCampo.xl, color: paleta.borde),
          Text(
            'Le pagas al proveedor al terminar, fuera de la app. La comisión '
            'de Agrocom ya está dentro de este precio: no se suma nada.',
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.valor, {this.tenue = false});

  final String etiqueta;
  final String valor;
  final bool tenue;

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
        fontWeight: tenue ? FontWeight.w600 : FontWeight.w800,
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
