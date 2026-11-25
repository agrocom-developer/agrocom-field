import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Calificación de 1 a 5 estrellas. Con [onCambio] es interactiva (la
/// escribe el cliente sobre el proveedor); sin él es de solo lectura (el
/// proveedor la ve en su perfil). Cada estrella es un objetivo táctil de
/// 48 px y anuncia "Calificación: 4 de 5" a los lectores de pantalla.
class CalificacionCampo extends StatelessWidget {
  const CalificacionCampo({
    required this.valor,
    this.onCambio,
    this.tamano = 28,
    super.key,
  }) : assert(valor >= 0 && valor <= 5);

  final int valor;
  final ValueChanged<int>? onCambio;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final lado = onCambio == null ? tamano : ObjetivoTactilCampo.minimo;
    return Semantics(
      container: true,
      label: 'Calificación: $valor de 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            _Estrella(
              llena: i <= valor,
              tamano: tamano,
              lado: lado,
              paleta: paleta,
              etiqueta: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
              onTap: onCambio == null
                  ? null
                  : () {
                      HapticaCampo.seleccion();
                      onCambio!(i);
                    },
            ),
        ],
      ),
    );
  }
}

class _Estrella extends StatelessWidget {
  const _Estrella({
    required this.llena,
    required this.tamano,
    required this.lado,
    required this.paleta,
    required this.etiqueta,
    required this.onTap,
  });

  final bool llena;
  final double tamano;
  final double lado;
  final PaletaCampo paleta;
  final String etiqueta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icono = AnimatedScale(
      scale: llena ? 1 : 0.88,
      duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
      curve: MovimientoCampo.entrada,
      child: Icon(
        llena ? Icons.star_rounded : Icons.star_outline_rounded,
        size: tamano,
        color: llena ? paleta.ambar : paleta.bordeFuerte,
      ),
    );
    if (onTap == null) {
      return SizedBox(width: lado, height: tamano, child: icono);
    }
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: lado / 2,
        child: SizedBox(width: lado, height: lado, child: icono),
      ),
    );
  }
}
