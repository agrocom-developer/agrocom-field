import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';

/// Estado vacío de una lista (pantalla 20 del diseño): ícono en un
/// contenedor tonal de 88, título, un texto con un dato útil y, si hay una
/// salida, una acción principal. Orienta: dice qué falta y qué hacer.
///
/// Sin [etiquetaAccion] queda como un aviso sin botón (la lista simplemente
/// no tiene nada todavía).
class EstadoVacioMarketplace extends StatelessWidget {
  const EstadoVacioMarketplace({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.etiquetaAccion,
    this.alAccion,
    super.key,
  }) : assert(
         (etiquetaAccion == null) == (alAccion == null),
         'La etiqueta y la acción van juntas',
       );

  final IconData icono;
  final String titulo;
  final String? detalle;

  /// Texto del botón principal, p. ej. «Ver lotes en el mapa».
  final String? etiquetaAccion;
  final VoidCallback? alAccion;

  /// Lado del contenedor tonal del ícono.
  static const double ladoContenedor = 88;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: ladoContenedor,
                height: ladoContenedor,
                decoration: BoxDecoration(
                  color: paleta.acentoContenedor,
                  borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
                ),
                child: Icon(
                  icono,
                  size: EspaciadoCampo.xl + EspaciadoCampo.s,
                  color: paleta.sobreAcentoContenedor,
                ),
              ),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            Semantics(
              header: true,
              child: Text(titulo, style: texto.headlineSmall),
            ),
            if (detalle != null) ...[
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                detalle!,
                style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
              ),
            ],
            if (etiquetaAccion != null) ...[
              const SizedBox(height: EspaciadoCampo.xl),
              FilledButton(
                key: const ValueKey('estado-vacio-accion'),
                onPressed: alAccion,
                child: Text(etiquetaAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
