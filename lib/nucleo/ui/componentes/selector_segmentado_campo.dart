import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Pill de N opciones con una seleccionada en lima — usado, por ejemplo,
/// para alternar entre dos variantes de un mismo formulario. Genérico sobre
/// [T] para no acoplarse a ningún enum de dominio del catálogo.
class SelectorSegmentadoCampo<T> extends StatelessWidget {
  const SelectorSegmentadoCampo({
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
    super.key,
  });

  final List<(T valor, String etiqueta)> opciones;
  final T seleccionado;
  final ValueChanged<T> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ColoresCampo.textoPrincipal.withValues(alpha: 0.055),
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final (valor, etiqueta) in opciones)
            Expanded(
              child: _Opcion(
                etiqueta: etiqueta,
                seleccionada: valor == seleccionado,
                onTap: () => onSeleccionar(valor),
              ),
            ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.etiqueta,
    required this.seleccionada,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13),
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
