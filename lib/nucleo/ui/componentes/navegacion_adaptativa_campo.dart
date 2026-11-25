import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'barra_inferior_campo.dart';

/// Destino de [NavegacionAdaptativaCampo].
class DestinoCampo {
  const DestinoCampo({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
}

/// Navegación raíz que se adapta al ancho: barra inferior en teléfono
/// (compacto), riel lateral en iPad y tabletas (medio y expandido; con
/// etiquetas extendidas en horizontal). El contenido se acota a 720 px de
/// ancho en pantallas anchas para que una lectura no se estire de borde a
/// borde.
class NavegacionAdaptativaCampo extends StatelessWidget {
  const NavegacionAdaptativaCampo({
    required this.destinos,
    required this.indice,
    required this.onSeleccionar,
    required this.cuerpo,
    this.anchoCompleto = false,
    super.key,
  }) : assert(destinos.length >= 2 && destinos.length <= 5);

  final List<DestinoCampo> destinos;
  final int indice;
  final ValueChanged<int> onSeleccionar;
  final Widget cuerpo;

  /// El cuerpo ocupa todo el ancho disponible en vez de acotarse a 720 px:
  /// para pantallas con panel dividido (mapa y formulario) en iPad.
  final bool anchoCompleto;

  void _seleccionar(int i) {
    if (i != indice) HapticaCampo.seleccion();
    onSeleccionar(i);
  }

  @override
  Widget build(BuildContext context) {
    final clase = ClasePantallaCampo.of(context);
    final paleta = context.paleta;
    final contenido = anchoCompleto
        ? cuerpo
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: cuerpo,
            ),
          );

    if (clase == ClasePantallaCampo.compacto) {
      return Scaffold(
        body: SafeArea(bottom: false, child: contenido),
        bottomNavigationBar: BarraInferiorCampo(
          destinos: destinos,
          indice: indice,
          onSeleccionar: _seleccionar,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: indice,
              onDestinationSelected: _seleccionar,
              extended: clase == ClasePantallaCampo.expandido,
              labelType: clase == ClasePantallaCampo.expandido
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinos)
                  NavigationRailDestination(
                    icon: Icon(d.icono),
                    selectedIcon: Icon(d.iconoActivo),
                    label: Text(d.etiqueta),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: paleta.borde),
            Expanded(child: contenido),
          ],
        ),
      ),
    );
  }
}
