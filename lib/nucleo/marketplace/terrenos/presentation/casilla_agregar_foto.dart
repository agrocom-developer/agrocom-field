import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import 'miniatura_foto_terreno.dart';

/// El botón cuadrado que agrega otra foto al terreno.
class CasillaAgregarFoto extends StatelessWidget {
  const CasillaAgregarFoto({required this.alToque, super.key});

  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: l10n.terrenosAgregarUnaFotoDel,
      excludeSemantics: true,
      child: Material(
        color: paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioCampo.media),
          side: BorderSide(color: paleta.bordeFuerte),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('fotos-terreno-agregar'),
          onTap: alToque,
          child: SizedBox.square(
            dimension: ladoMiniaturaFoto,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: paleta.acentoTexto),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      l10n.terrenosAgregar,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: paleta.acentoTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
