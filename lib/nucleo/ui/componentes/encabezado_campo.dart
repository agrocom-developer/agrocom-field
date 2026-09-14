import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Header con botón "volver" circular + título — reemplaza el `AppBar` de
/// Material en pantallas que adoptan el modo campo (el `AppBar` estándar no
/// encaja con un `Scaffold` de fondo transparente sobre imagen/textura).
/// [accion] es un segundo botón circular opcional a la derecha (p. ej. "⋯").
class EncabezadoCampo extends StatelessWidget implements PreferredSizeWidget {
  const EncabezadoCampo({
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.onAccionPresionada,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? accion;
  final VoidCallback? onAccionPresionada;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Row(
        children: [
          _BotonCircular(
            icono: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: ColoresCampo.textoPrincipal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: ColoresCampo.textoPrincipal.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (accion != null)
            _BotonCircular(icono: accion!, onPressed: onAccionPresionada),
        ],
      ),
    );
  }
}

class _BotonCircular extends StatelessWidget {
  const _BotonCircular({required this.icono, required this.onPressed});

  final IconData icono;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.16),
        ),
      ),
      child: IconButton(
        icon: Icon(icono, color: ColoresCampo.textoPrincipal, size: 18),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
