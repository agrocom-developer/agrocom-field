import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import 'fila_lote.dart';

/// «Mis lotes»: los lotes registrados del cliente, que salieron del perfil.
/// La acción principal, «Publicar lote», va al pie (zona del pulgar).
class MisLotesPantalla extends StatelessWidget {
  const MisLotesPantalla({required this.lotes, this.alPublicar, super.key});

  final List<Lote> lotes;

  /// Abre el flujo de publicar un lote; sin él no se muestra el botón.
  final VoidCallback? alPublicar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Scaffold(
      appBar: AppBar(title: Text(t.perfilMisCampos)),
      body: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          if (lotes.isEmpty)
            Text(
              t.perfilMisCamposVacio,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: paleta.textoSecundario),
            )
          else
            SuperficieMarketplace(
              padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
              child: Column(
                children: [for (final lote in lotes) FilaLote(lote: lote)],
              ),
            ),
        ],
      ),
      bottomNavigationBar: alPublicar == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(EspaciadoCampo.l),
              child: BotonPrimarioCampo(
                key: const Key('mis-lotes-publicar'),
                texto: t.publicarLote,
                onPressed: alPublicar,
              ),
            ),
    );
  }
}
