import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/superficie_marketplace.dart';
import '../paleta_campo.dart';
import '../tema_visual/tema_visual_cubit.dart';
import '../tokens_campo.dart';

/// Ajustes → Apariencia: dos vistas previas (Claro y Oscuro) con un radio
/// debajo de cada una. Al elegir, la app cambia en el acto y la elección se
/// guarda. Sin elección previa, se marca Claro (el predeterminado de las dos
/// apps).
class AparienciaPantalla extends StatelessWidget {
  const AparienciaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final elegido = context.select<TemaVisualCubit, ModoVisualCampo?>(
      (c) => c.state,
    );
    final actual = elegido ?? ModoVisualCampo.claro;
    return Scaffold(
      appBar: AppBar(title: Text(t.aparienciaTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          SuperficieMarketplace(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    t.aparienciaTema,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                Row(
                  children: [
                    Expanded(
                      child: _OpcionTema(
                        modo: ModoVisualCampo.claro,
                        etiqueta: t.aparienciaTemaClaro,
                        activa: actual == ModoVisualCampo.claro,
                      ),
                    ),
                    const SizedBox(width: EspaciadoCampo.l),
                    Expanded(
                      child: _OpcionTema(
                        modo: ModoVisualCampo.oscuro,
                        etiqueta: t.aparienciaTemaOscuro,
                        activa: actual == ModoVisualCampo.oscuro,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionTema extends StatelessWidget {
  const _OpcionTema({
    required this.modo,
    required this.etiqueta,
    required this.activa,
  });

  final ModoVisualCampo modo;
  final String etiqueta;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: activa,
      label: etiqueta,
      excludeSemantics: true,
      child: InkWell(
        key: Key('apariencia-${modo.name}'),
        borderRadius: BorderRadius.circular(RadioCampo.media),
        onTap: () => context.read<TemaVisualCubit>().elegir(modo),
        child: Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.xs),
          child: Column(
            children: [
              _VistaPrevia(modo: modo, activa: activa),
              const SizedBox(height: EspaciadoCampo.m),
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              AnimatedSwitcher(
                duration: MovimientoCampo.duracion(
                  context,
                  MovimientoCampo.rapida,
                ),
                child: Icon(
                  activa
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(activa),
                  color: activa ? paleta.acentoTexto : paleta.bordeFuerte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini teléfono dibujado con los colores del tema que representa.
class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.modo, required this.activa});

  final ModoVisualCampo modo;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final propia = context.paleta;
    final p = PaletaCampo.deModo(modo);
    return AnimatedContainer(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
      curve: MovimientoCampo.entrada,
      height: 160,
      padding: const EdgeInsets.all(EspaciadoCampo.s),
      decoration: BoxDecoration(
        color: p.fondo,
        borderRadius: BorderRadius.circular(RadioCampo.campo),
        border: Border.all(
          color: activa ? propia.acentoTexto : propia.bordeFuerte,
          width: activa ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Barra(color: p.cabecera, ancho: double.infinity, alto: 28),
          const SizedBox(height: EspaciadoCampo.s),
          _Barra(color: p.texto, ancho: 48, alto: 6),
          const SizedBox(height: EspaciadoCampo.xs),
          _Barra(color: p.textoSecundario, ancho: 32, alto: 6),
          const SizedBox(height: EspaciadoCampo.s),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.superficie,
                borderRadius: BorderRadius.circular(RadioCampo.chip),
                border: Border.all(color: p.borde),
              ),
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          _Barra(color: p.ambar, ancho: double.infinity, alto: 16),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.color, required this.ancho, required this.alto});

  final Color color;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(RadioCampo.xs),
    ),
  );
}
