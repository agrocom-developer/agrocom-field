import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Tono semántico de un [ChipEstadoMarketplace].
enum TonoEstado { exito, info, alerta, error, neutro }

/// Estado en una píldora: ícono + texto sobre un fondo tenue del tono. El
/// ícono y el texto portan el significado; el color solo lo refuerza
/// (sistema visual, §2), así se lee igual bajo el sol o con daltonismo.
class ChipEstadoMarketplace extends StatelessWidget {
  const ChipEstadoMarketplace({
    required this.etiqueta,
    required this.tono,
    required this.icono,
    this.etiquetaSemantica,
    super.key,
  });

  final String etiqueta;
  final TonoEstado tono;
  final IconData icono;

  /// Lo que anuncia el lector de pantalla. Por defecto, «Estado: [etiqueta]».
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final (fondo, color) = switch (tono) {
      TonoEstado.exito => (
        paleta.acentoContenedor,
        paleta.sobreAcentoContenedor,
      ),
      TonoEstado.info => (paleta.infoContenedor, paleta.sobreInfoContenedor),
      TonoEstado.alerta => (
        paleta.ambarContenedor,
        paleta.sobreAmbarContenedor,
      ),
      TonoEstado.error => (paleta.errorContenedor, paleta.sobreErrorContenedor),
      TonoEstado.neutro => (paleta.superficie2, paleta.textoSecundario),
    };
    return Semantics(
      container: true,
      label: etiquetaSemantica ?? l10n.uiEstado(etiqueta),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.xs + 2,
        ),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(RadioCampo.capsula),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: EspaciadoCampo.xs + 2),
            Flexible(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
