import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Tamaño de radio de [TarjetaCampo] — evita que cada pantalla elija un
/// número suelto (ver ADR 0008).
enum TamanoTarjetaCampo { grande, chica }

/// Superficie translúcida + borde 1px sobre `fondoProfundo` — la unidad de
/// agrupación visual del modo campo (reemplaza `Card` en las pantallas que
/// lo adoptan). El acento es opcional: una tarjeta "resaltada" (p. ej. el
/// trabajo asignado) usa `acento: ColoresCampo.acentoLima`.
class TarjetaCampo extends StatelessWidget {
  const TarjetaCampo({
    required this.child,
    this.tamano = TamanoTarjetaCampo.chica,
    this.acento,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final TamanoTarjetaCampo tamano;

  /// Color de borde/fondo alternativo al translúcido neutro por defecto.
  final Color? acento;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radio = tamano == TamanoTarjetaCampo.grande ? 24.0 : 18.0;
    final colorAcento = acento;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            colorAcento?.withValues(alpha: 0.1) ??
            ColoresCampo.textoPrincipal.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(
          color:
              colorAcento?.withValues(alpha: 0.34) ??
              ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}
