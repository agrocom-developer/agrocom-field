import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Slot con borde punteado — "agregar producto", o el hueco de una
/// evidencia obligatoria todavía sin capturar. [alerta] lo tiñe de ámbar en
/// vez del lima por defecto, para el caso "obligatorio y falta".
class BotonAgregarPunteadoCampo extends StatelessWidget {
  const BotonAgregarPunteadoCampo({
    required this.texto,
    required this.onPressed,
    this.alerta = false,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final color = alerta ? ColoresCampo.acentoAmbar : ColoresCampo.acentoLima;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Borde sólido, no punteado: Flutter no trae `dashed` sin un
          // paquete de `CustomPainter` aparte — no se justifica solo por
          // esto (ver ADR 0008, criterio de no sumar dependencias nuevas).
          border: Border.all(
            color: color.withValues(alpha: alerta ? 0.45 : 0.22),
          ),
          color: alerta ? color.withValues(alpha: 0.07) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: alerta ? ColoresCampo.acentoAmbarTexto : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
