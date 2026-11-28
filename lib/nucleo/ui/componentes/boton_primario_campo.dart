import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tema_campo.dart';

/// CTA pill en ámbar (el 10 % de acento del sistema 60/30/10) — alto mínimo 56 (mismo criterio de touch target que
/// ADR 0003: guantes, sol directo). Único botón "lleno" del catálogo de
/// campo; para acciones secundarias, `BotonSecundarioCampo`.
///
/// El alto es un mínimo, no un valor fijo: con el texto escalado al 200 %
/// el botón crece en vez de cortar la etiqueta.
class BotonPrimarioCampo extends StatelessWidget {
  const BotonPrimarioCampo({
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.icono,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  /// Ícono opcional a la izquierda de la etiqueta; nunca reemplaza al texto.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final radio = Theme.of(context).extension<TemaCampo>()?.radioPill ?? 999;
    const etiqueta = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FilledButton(
        onPressed: cargando ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: paleta.ambar,
          disabledBackgroundColor: paleta.ambar.withValues(alpha: 0.4),
          foregroundColor: paleta.sobreAmbar,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
        ),
        child: cargando
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: paleta.sobreAmbar,
                ),
              )
            : icono == null
            ? Text(texto, textAlign: TextAlign.center, style: etiqueta)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: etiqueta,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
