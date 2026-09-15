import 'package:flutter/material.dart';

import '../tipografia_campo.dart';
import 'boton_circular_campo.dart';

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
          BotonCircularCampo(
            icono: Icons.arrow_back,
            tooltip: 'Volver',
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
                  style: TipografiaCampo.tituloSeccion,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: TipografiaCampo.datoMono,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (accion != null)
            BotonCircularCampo(icono: accion!, onPressed: onAccionPresionada),
        ],
      ),
    );
  }
}
