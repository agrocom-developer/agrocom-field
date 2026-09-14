import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Un ítem de [BarraNavegacionCampo]. [insignia] es el número de un badge
/// opcional (p. ej. "Sync 4"), mostrado en `acentoAmbar` junto al label.
class ItemBarraNavegacionCampo {
  const ItemBarraNavegacionCampo({
    required this.icono,
    required this.etiqueta,
    this.insignia,
  });

  final IconData icono;
  final String etiqueta;
  final int? insignia;
}

/// Bottom nav con un botón de acción central elevado (el "+" del mockup) —
/// distinto de `NavigationBar` de Material, que no tiene ese slot central.
/// El ítem activo se pinta en `acentoLima`; el resto, atenuado.
class BarraNavegacionCampo extends StatelessWidget {
  const BarraNavegacionCampo({
    required this.items,
    required this.indiceActivo,
    required this.onSeleccionar,
    required this.onAccionCentral,
    super.key,
  });

  final List<ItemBarraNavegacionCampo> items;
  final int indiceActivo;
  final ValueChanged<int> onSeleccionar;
  final VoidCallback onAccionCentral;

  @override
  Widget build(BuildContext context) {
    final mitad = items.length ~/ 2;
    return Container(
      height: 88,
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ColoresCampo.fondoProfundo.withValues(alpha: 0.75),
        border: Border(
          top: BorderSide(
            color: ColoresCampo.textoPrincipal.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var indice = 0; indice < items.length; indice++) ...[
            _Item(
              item: items[indice],
              activo: indice == indiceActivo,
              onTap: () => onSeleccionar(indice),
            ),
            if (indice == mitad - 1) _BotonCentral(onTap: onAccionCentral),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.activo, required this.onTap});

  final ItemBarraNavegacionCampo item;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo
        ? ColoresCampo.acentoLima
        : ColoresCampo.textoPrincipal.withValues(alpha: 0.5);
    final etiqueta = item.insignia == null
        ? item.etiqueta
        : '${item.etiqueta} ${item.insignia}';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icono, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: item.insignia != null && !activo
                  ? ColoresCampo.acentoAmbar
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonCentral extends StatelessWidget {
  const _BotonCentral({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ColoresCampo.acentoLima,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: ColoresCampo.fondoProfundo,
            size: 28,
          ),
        ),
      ),
    );
  }
}
