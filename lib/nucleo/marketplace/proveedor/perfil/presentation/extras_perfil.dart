import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tema_visual/selector_tema_visual.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../../negociacion/presentation/avisos_pantalla.dart';

/// Las filas de cuenta que van en el perfil de `piloto`: los
/// avisos (solo con negociación) y cerrar sesión (solo en la app real).
List<Widget> extrasDePerfil(
  BuildContext context, {
  required bool conAvisos,
  VoidCallback? alSalir,
}) {
  final t = AppLocalizations.of(context);
  return [
    const SuperficieMarketplace(
      key: Key('perfil-tema'),
      child: SelectorTemaVisual(predeterminado: ModoVisualCampo.claro),
    ),
    if (conAvisos)
      FilaAccionPerfil(
        clave: const Key('perfil-avisos'),
        icono: Icons.notifications_active_outlined,
        titulo: t.perfilProveedorAvisos,
        detalle: t.perfilProveedorAvisosDetalle,
        alToque: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AvisosPantalla())),
      ),
    if (alSalir != null)
      FilaAccionPerfil(
        clave: const Key('perfil-salir'),
        icono: Icons.logout_rounded,
        titulo: t.perfilCerrarSesion,
        detalle: t.perfilProveedorCerrarSesionDetalle,
        alToque: alSalir,
      ),
  ];
}

class FilaAccionPerfil extends StatelessWidget {
  const FilaAccionPerfil({
    required this.icono,
    required this.titulo,
    required this.alToque,
    this.detalle,
    this.clave,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alToque;
  final Key? clave;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: detalle == null ? titulo : '$titulo. $detalle',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        key: clave,
        onTap: alToque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
          ),
          child: Row(
            children: [
              Icon(icono, color: context.paleta.acentoTexto),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleMedium),
                    if (detalle != null)
                      Text(
                        detalle!,
                        style: texto.bodyMedium?.copyWith(
                          color: context.paleta.textoSecundario,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.paleta.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
