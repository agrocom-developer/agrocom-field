import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/encabezado_de_marca.dart';
import '../../../../ui/componentes/lista_de_capacidades.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';

/// Portada de la app del piloto, antes del ingreso: dice que es la app DE
/// PILOTO (marca «DronAgro» con el distintivo «Piloto») y lista qué puede
/// hacer un piloto aquí. Las acciones quedan fijas abajo, al alcance del
/// pulgar y con objetivos de 56 dp; la lista se desplaza si no cabe.
class PortadaPilotoPantalla extends StatelessWidget {
  const PortadaPilotoPantalla({
    required this.alEntrar,
    this.alRegistrarse,
    super.key,
  });

  final VoidCallback alEntrar;

  /// Si es nulo (registro cerrado en este build) no se ofrece el alta.
  final VoidCallback? alRegistrarse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    key: const Key('portada-piloto-lista'),
                    padding: const EdgeInsets.all(EspaciadoCampo.xl),
                    children: [
                      const EncabezadoDeMarca(rol: RolApp.piloto),
                      const SizedBox(height: EspaciadoCampo.l),
                      Text(
                        l10n.portadaPilotoLema,
                        style: texto.titleMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.xl),
                      const ListaDeCapacidades(rol: RolApp.piloto),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EspaciadoCampo.xl,
                    EspaciadoCampo.s,
                    EspaciadoCampo.xl,
                    EspaciadoCampo.l,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BotonPrincipalMarketplace(
                        key: const Key('portada-piloto-entrar'),
                        texto: l10n.portadaPilotoEntrar,
                        onPressed: alEntrar,
                      ),
                      if (alRegistrarse != null) ...[
                        const SizedBox(height: EspaciadoCampo.s),
                        TextButton(
                          key: const Key('portada-piloto-registro'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              ObjetivoTactilCampo.guantes,
                            ),
                          ),
                          onPressed: alRegistrarse,
                          child: Text(
                            l10n.proveedorAccesoSoyPilotoQuieroRegistrarme,
                          ),
                        ),
                      ],
                    ],
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
