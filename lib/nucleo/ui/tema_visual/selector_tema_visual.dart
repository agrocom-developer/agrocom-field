import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'tema_visual_cubit.dart';

/// «Tema»: Claro, Oscuro o Campo AAA. Al elegir, la app cambia en el acto y
/// la elección se guarda para el próximo arranque.
class SelectorTemaVisual extends StatelessWidget {
  const SelectorTemaVisual({required this.predeterminado, super.key});

  /// El tema del flavor mientras no se haya elegido otro.
  final ModoVisualCampo predeterminado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final elegido = context.select<TemaVisualCubit, ModoVisualCampo?>(
      (c) => c.state,
    );
    final brilloSistema = MediaQuery.platformBrightnessOf(context);
    // El cliente sin elección sigue al sistema: se marca lo que se ve.
    final actual =
        elegido ??
        (predeterminado == ModoVisualCampo.claro
            ? (brilloSistema == Brightness.dark
                  ? ModoVisualCampo.oscuro
                  : ModoVisualCampo.claro)
            : predeterminado);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            t.temaTitulo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Container(
          padding: const EdgeInsets.all(EspaciadoCampo.xs),
          decoration: BoxDecoration(
            color: context.paleta.superficie2,
            borderRadius: BorderRadius.circular(RadioCampo.media),
          ),
          child: Row(
            children: [
              for (final (modo, etiqueta) in [
                (ModoVisualCampo.claro, t.temaClaro),
                (ModoVisualCampo.oscuro, t.temaOscuro),
                (ModoVisualCampo.campo, t.temaCampo),
              ])
                Expanded(
                  child: _Segmento(
                    etiqueta: etiqueta,
                    activo: modo == actual,
                    alTocar: () => context.read<TemaVisualCubit>().elegir(modo),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.etiqueta,
    required this.activo,
    required this.alTocar,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: activo,
      label: etiqueta,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: alTocar,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.minimo,
          ),
          padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? paleta.superficie : Colors.transparent,
            borderRadius: BorderRadius.circular(RadioCampo.chip),
            border: activo ? Border.all(color: paleta.borde) : null,
          ),
          child: Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
              color: activo ? paleta.texto : paleta.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}
