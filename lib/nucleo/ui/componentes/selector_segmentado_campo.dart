import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Pill de N opciones con una seleccionada en lima — usado, por ejemplo,
/// para alternar entre dos variantes de un mismo formulario. Genérico sobre
/// [T] para no acoplarse a ningún enum de dominio del catálogo.
///
/// Con pocas opciones (2-4) reparten el ancho en partes iguales; con más,
/// [desplazable] las deja a su ancho natural en una fila que se desplaza
/// horizontalmente (filtros, pestañas de una vista previa).
class SelectorSegmentadoCampo<T> extends StatelessWidget {
  const SelectorSegmentadoCampo({
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
    this.desplazable = false,
    super.key,
  });

  final List<(T valor, String etiqueta)> opciones;
  final T seleccionado;
  final ValueChanged<T> onSeleccionar;
  final bool desplazable;

  @override
  Widget build(BuildContext context) {
    final fila = Row(
      mainAxisSize: desplazable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (final (valor, etiqueta) in opciones)
          if (desplazable)
            _Opcion(
              etiqueta: etiqueta,
              seleccionada: valor == seleccionado,
              compacta: true,
              onTap: () => onSeleccionar(valor),
            )
          else
            Expanded(
              child: _Opcion(
                etiqueta: etiqueta,
                seleccionada: valor == seleccionado,
                compacta: false,
                onTap: () => onSeleccionar(valor),
              ),
            ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ColoresCampo.textoPrincipal.withValues(alpha: 0.055),
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: desplazable
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: fila)
          : fila,
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.etiqueta,
    required this.seleccionada,
    required this.compacta,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionada;
  final bool compacta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          vertical: 13,
          horizontal: compacta ? 18 : 0,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionada ? ColoresCampo.acentoLima : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: seleccionada
                ? ColoresCampo.fondoProfundo
                : ColoresCampo.textoPrincipal.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
