import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'navegacion_adaptativa_campo.dart';

/// Barra inferior de cuatro destinos del sistema visual: el destino activo
/// lleva un indicador tonal de 56×30 (radio 15, `acentoContenedor`) detrás
/// del ícono y su etiqueta en 12/800; los demás, ícono y etiqueta atenuados.
/// Cada destino mide al menos 64 de alto, por encima del objetivo táctil
/// mínimo, y su etiqueta crece con el texto escalado.
class BarraInferiorCampo extends StatelessWidget {
  const BarraInferiorCampo({
    required this.destinos,
    required this.indice,
    required this.onSeleccionar,
    super.key,
  }) : assert(destinos.length >= 2 && destinos.length <= 5);

  final List<DestinoCampo> destinos;
  final int indice;
  final ValueChanged<int> onSeleccionar;

  /// Medidas del indicador tonal (sistema visual, «Barra inferior»).
  static const double anchoIndicador = 56;
  static const double altoIndicador = 30;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.superficie,
        border: Border(top: BorderSide(color: paleta.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < destinos.length; i++)
              Expanded(
                child: _Destino(
                  destino: destinos[i],
                  activo: i == indice,
                  posicion: i + 1,
                  total: destinos.length,
                  onTap: () => onSeleccionar(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Destino extends StatelessWidget {
  const _Destino({
    required this.destino,
    required this.activo,
    required this.posicion,
    required this.total,
    required this.onTap,
  });

  final DestinoCampo destino;
  final bool activo;
  final int posicion;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      selected: activo,
      label: destino.etiqueta,
      hint: '$posicion / $total',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: MovimientoCampo.duracion(
                    context,
                    MovimientoCampo.rapida,
                  ),
                  curve: MovimientoCampo.entrada,
                  width: BarraInferiorCampo.anchoIndicador,
                  height: BarraInferiorCampo.altoIndicador,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activo
                        ? paleta.acentoContenedor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      BarraInferiorCampo.altoIndicador / 2,
                    ),
                  ),
                  child: Icon(
                    activo ? destino.iconoActivo : destino.icono,
                    size: 22,
                    color: activo
                        ? paleta.sobreAcentoContenedor
                        : paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  destino.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaCampo.etiqueta.copyWith(
                    fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                    color: activo ? paleta.texto : paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
