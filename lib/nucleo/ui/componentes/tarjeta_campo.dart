import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Tamaño de radio de [TarjetaCampo] — evita que cada pantalla elija un
/// número suelto (ver ADR 0008).
enum TamanoTarjetaCampo { grande, chica }

/// Superficie translúcida + borde 1px sobre `fondoProfundo` — la unidad de
/// agrupación visual del modo campo (reemplaza `Card` en las pantallas que
/// lo adoptan). El acento es opcional: una tarjeta "resaltada" (p. ej. el
/// trabajo asignado) usa `acento: ColoresCampo.acentoLima`.
///
/// Con [onTap] la tarjeta entera es tocable, con el ripple de Material
/// recortado a su radio — para una fila de lista que navega (orden, rol),
/// no para tarjetas que solo agrupan contenido.
class TarjetaCampo extends StatelessWidget {
  const TarjetaCampo({
    required this.child,
    this.tamano = TamanoTarjetaCampo.chica,
    this.acento,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    super.key,
  });

  final Widget child;
  final TamanoTarjetaCampo tamano;

  /// Color de borde/fondo alternativo al translúcido neutro por defecto.
  final Color? acento;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radio = tamano == TamanoTarjetaCampo.grande ? 24.0 : 18.0;
    final colorAcento = acento;
    final decoracion = BoxDecoration(
      color:
          colorAcento?.withValues(alpha: 0.1) ??
          ColoresCampo.textoPrincipal.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(radio),
      border: Border.all(
        color:
            colorAcento?.withValues(alpha: 0.34) ??
            ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
      ),
    );
    if (onTap == null) {
      return Container(padding: padding, decoration: decoracion, child: child);
    }
    return Container(
      decoration: decoracion,
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
