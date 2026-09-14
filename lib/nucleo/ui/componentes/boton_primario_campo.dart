import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tema_campo.dart';

/// CTA pill en lima — alto mínimo 56 (mismo criterio de touch target que
/// ADR 0003: guantes, sol directo). Único botón "lleno" del catálogo de
/// campo; para acciones secundarias, `BotonSecundarioCampo`.
class BotonPrimarioCampo extends StatelessWidget {
  const BotonPrimarioCampo({
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final radio = Theme.of(context).extension<TemaCampo>()?.radioPill ?? 999;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: cargando ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ColoresCampo.acentoLima,
          disabledBackgroundColor: ColoresCampo.acentoLima.withValues(
            alpha: 0.4,
          ),
          foregroundColor: ColoresCampo.fondoProfundo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
        ),
        child: cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColoresCampo.fondoProfundo,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
