import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';

/// Tarjeta del marketplace: superficie de la paleta activa con borde de 1 px
/// (sistema visual, §5). A diferencia de `TarjetaCampo` (modo campo fijo),
/// lee `PaletaCampo` y funciona en los tres modos.
class SuperficieMarketplace extends StatelessWidget {
  const SuperficieMarketplace({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EspaciadoCampo.l),
    this.radio = RadioCampo.tarjetaCompacta,
    this.resaltada = false,
    this.colorBorde,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radio;

  /// Borde de acento para el elemento protagonista de la pantalla.
  final bool resaltada;

  /// Borde de otro color (ámbar para «es tu turno»); gana sobre [resaltada].
  final Color? colorBorde;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final forma = BorderRadius.circular(radio);
    return Material(
      color: paleta.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: forma,
        side: BorderSide(
          color: colorBorde ?? (resaltada ? paleta.acentoTexto : paleta.borde),
          width: colorBorde != null ? 2 : (resaltada ? 1.5 : 1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}
