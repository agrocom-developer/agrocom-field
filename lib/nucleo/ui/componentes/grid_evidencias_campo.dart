import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Una celda de [GridEvidenciasCampo]: ya capturada (miniatura + [etiqueta])
/// o pendiente (`miniatura: null`, se pinta como slot "agregar").
class CeldaEvidenciaCampo {
  const CeldaEvidenciaCampo({
    required this.etiqueta,
    this.miniatura,
    this.obligatoria = true,
  });

  final String etiqueta;
  final ImageProvider? miniatura;
  final bool obligatoria;
}

/// Grid 2x2 de evidencias fotográficas (control, ciclo de batería, dron
/// limpio, etc.) — una celda sin [CeldaEvidenciaCampo.miniatura] se muestra
/// como slot "agregar", en ámbar si es obligatoria.
class GridEvidenciasCampo extends StatelessWidget {
  const GridEvidenciasCampo({
    required this.celdas,
    required this.onAgregar,
    super.key,
  });

  final List<CeldaEvidenciaCampo> celdas;
  final ValueChanged<int> onAgregar;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: celdas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, indice) {
        final celda = celdas[indice];
        if (celda.miniatura != null) {
          return _CeldaCapturada(celda: celda);
        }
        return _CeldaPendiente(celda: celda, onTap: () => onAgregar(indice));
      },
    );
  }
}

class _CeldaCapturada extends StatelessWidget {
  const _CeldaCapturada({required this.celda});

  final CeldaEvidenciaCampo celda;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.1),
        ),
        image: DecorationImage(image: celda.miniatura!, fit: BoxFit.cover),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(10),
      child: Text(
        celda.etiqueta,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: ColoresCampo.textoPrincipal.withValues(alpha: 0.85),
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
    );
  }
}

class _CeldaPendiente extends StatelessWidget {
  const _CeldaPendiente({required this.celda, required this.onTap});

  final CeldaEvidenciaCampo celda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = celda.obligatoria
        ? ColoresCampo.acentoAmbar
        : ColoresCampo.acentoLima;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: color, size: 19),
            const SizedBox(height: 6),
            Text(
              celda.etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
