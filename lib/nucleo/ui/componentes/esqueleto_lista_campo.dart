import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Un bloque de [EsqueletoListaCampo]: la forma de lo que va a llegar.
class BloqueEsqueleto {
  const BloqueEsqueleto({this.ancho, this.alto = 16, this.radio = 8});

  final double? ancho;
  final double alto;
  final double radio;
}

/// Esqueleto de carga del flavor `cliente` (online-first), con `skeletonizer`.
/// El piloto lee de `drift` y no lo usa. Respeta «reducir movimiento»: sin
/// barrido, solo los bloques tenues. [separacion] va entre bloques.
class EsqueletoListaCampo extends StatelessWidget {
  const EsqueletoListaCampo({
    required this.bloques,
    this.separacion = EspaciadoCampo.m,
    super.key,
  });

  final List<BloqueEsqueleto> bloques;
  final double separacion;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final base = paleta.texto.withValues(alpha: 0.08);
    final brillo = paleta.texto.withValues(alpha: 0.16);
    final hijos = <Widget>[];
    for (var i = 0; i < bloques.length; i++) {
      final b = bloques[i];
      if (i > 0) hijos.add(SizedBox(height: separacion));
      hijos.add(
        Bone(
          width: b.ancho,
          height: b.alto,
          borderRadius: BorderRadius.circular(b.radio),
        ),
      );
    }
    return Semantics(
      label: 'Cargando',
      excludeSemantics: true,
      child: Skeletonizer(
        effect: MovimientoCampo.reducido(context)
            ? SolidColorEffect(color: base)
            : ShimmerEffect(
                baseColor: base,
                highlightColor: brillo,
                duration: MovimientoCampo.esqueleto,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hijos,
        ),
      ),
    );
  }
}
