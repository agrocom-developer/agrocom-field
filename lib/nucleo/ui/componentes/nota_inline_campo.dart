import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tipografia_campo.dart';

/// Nota corta de una línea con un punto de color adelante ("● Se guarda
/// local y queda pendiente de sync", "● Sin conexión") — el aviso de estado
/// que va pegado a un botón primario, sin el peso de un `BannerAlertaCampo`
/// ni el recuadro de una `NotaTecnicaCampo`. [color] es semántico: ámbar
/// (pendiente/alerta) por defecto, rojo para un error, lima para un ok.
class NotaInlineCampo extends StatelessWidget {
  const NotaInlineCampo({
    required this.texto,
    this.color = ColoresCampo.acentoAmbarTexto,
    this.centrada = false,
    super.key,
  });

  final String texto;
  final Color color;
  final bool centrada;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: centrada ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: centrada
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            texto,
            textAlign: centrada ? TextAlign.center : TextAlign.start,
            style: TipografiaCampo.datoMono.copyWith(
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: OpacidadesCampo.casiPlena),
            ),
          ),
        ),
      ],
    );
  }
}
