import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Radio de las opciones: el del botón del tema claro y oscuro.
const radioOpcion = 14.0;

/// Opción seleccionable del formulario (cultivo, producto, horario). El
/// estado elegido lleva tilde y borde de acento además del color, de modo
/// que nunca depende solo del color.
///
/// Sin [apoyo] es una pastilla que se acomoda en un `Wrap`; con [apoyo]
/// ocupa el ancho completo con el título y una línea de contexto.
class OpcionSolicitud extends StatelessWidget {
  const OpcionSolicitud({
    required this.titulo,
    required this.elegida,
    required this.alElegir,
    this.apoyo,
    super.key,
  });

  final String titulo;
  final String? apoyo;
  final bool elegida;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final ancha = apoyo != null;
    final forma = BorderRadius.circular(radioOpcion);
    final icono = Icon(
      ancha
          ? (elegida
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded)
          : Icons.check_rounded,
      size: ancha ? 24 : 18,
      color: elegida ? paleta.acentoTexto : paleta.bordeFuerte,
    );
    final titular = Text(
      titulo,
      style: texto.titleMedium?.copyWith(
        fontWeight: elegida ? FontWeight.w800 : FontWeight.w600,
      ),
    );

    return Semantics(
      button: true,
      selected: elegida,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
        constraints: const BoxConstraints(
          minHeight: ObjetivoTactilCampo.minimo,
        ),
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
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.m,
              ),
              child: ancha
                  ? Row(
                      children: [
                        icono,
                        const SizedBox(width: EspaciadoCampo.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titular,
                              const SizedBox(height: 2),
                              Text(
                                apoyo!,
                                style: texto.bodySmall?.copyWith(
                                  color: paleta.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (elegida) ...[
                          icono,
                          const SizedBox(width: EspaciadoCampo.xs),
                        ],
                        Flexible(child: titular),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de un grupo de opciones dentro de un paso.
class TituloGrupoSolicitud extends StatelessWidget {
  const TituloGrupoSolicitud(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: EspaciadoCampo.xl,
        bottom: EspaciadoCampo.s,
      ),
      child: Semantics(
        header: true,
        child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
