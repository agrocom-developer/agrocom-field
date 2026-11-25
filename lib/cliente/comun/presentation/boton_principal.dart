import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// La acción principal de una pantalla del cliente: una sola por pantalla,
/// a todo el ancho. Crece en alto con el texto ampliado en lugar de cortarlo.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    required this.texto,
    required this.onPressed,
    this.icono,
    this.cargando = false,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  /// Muestra un indicador y bloquea el toque mientras la acción viaja.
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Semantics(
      button: true,
      enabled: onPressed != null && !cargando,
      label: cargando ? l10n.comunEnviando(texto) : texto,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: cargando ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, ObjetivoTactilCampo.guantes),
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.xl,
              vertical: EspaciadoCampo.m,
            ),
            // Deshabilitado: superficie neutra con texto de apoyo (sin alpha).
            disabledBackgroundColor: paleta.superficie2,
            disabledForegroundColor: paleta.textoSecundario,
          ),
          child: AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
            child: cargando
                ? SizedBox.square(
                    key: const ValueKey('cargando'),
                    dimension: EspaciadoCampo.xl,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: paleta.sobreAcento,
                    ),
                  )
                : Row(
                    key: ValueKey(texto),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icono != null) ...[
                        Icon(icono, size: 20),
                        const SizedBox(width: EspaciadoCampo.s),
                      ],
                      Flexible(child: Text(texto, textAlign: TextAlign.center)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
