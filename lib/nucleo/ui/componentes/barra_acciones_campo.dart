import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Zona de acciones anclada al borde inferior de una pantalla del lote: la
/// acción principal queda siempre a la altura del pulgar, sin scroll, con
/// la secundaria encima (sistema visual, §1: una acción principal por
/// pantalla, visible sin scroll). Respeta el área segura inferior.
class BarraAccionesCampo extends StatelessWidget {
  const BarraAccionesCampo({
    required this.principal,
    this.secundaria,
    this.nota,
    super.key,
  });

  /// Acción principal (un `BotonPrimarioCampo`, o la nota que la reemplaza
  /// cuando ya no hay nada por hacer).
  final Widget principal;

  /// Acción secundaria, encima de la principal.
  final Widget? secundaria;

  /// Línea de apoyo sobre las acciones (estado de guardado, motivo de un
  /// bloqueo).
  final Widget? nota;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(top: BorderSide(color: paleta.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margen,
            EspaciadoCampo.m,
            margen,
            EspaciadoCampo.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (nota != null) ...[
                nota!,
                const SizedBox(height: EspaciadoCampo.m),
              ],
              if (secundaria != null) ...[
                secundaria!,
                const SizedBox(height: EspaciadoCampo.m),
              ],
              principal,
            ],
          ),
        ),
      ),
    );
  }
}
