import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Menú de tres puntos del perfil: Ajustes, Apariencia, las [extras] del
/// flavor y, separado, Cerrar sesión en color de error. Cada entrada solo
/// aparece si se le da su acción. Va en la esquina de [CabeceraPerfilCampo].
class MenuPerfilCampo extends StatelessWidget {
  const MenuPerfilCampo({
    this.alAjustes,
    this.alApariencia,
    this.alSalir,
    this.extras = const [],
    super.key,
  });

  final VoidCallback? alAjustes;
  final VoidCallback? alApariencia;
  final VoidCallback? alSalir;
  final List<({IconData icono, String etiqueta, VoidCallback alToque})> extras;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final entradas =
        <({IconData icono, String etiqueta, VoidCallback alToque})>[
          if (alAjustes != null)
            (
              icono: Icons.settings_outlined,
              etiqueta: t.ajustesTitulo,
              alToque: alAjustes!,
            ),
          if (alApariencia != null)
            (
              icono: Icons.palette_outlined,
              etiqueta: t.ajustesApariencia,
              alToque: alApariencia!,
            ),
          ...extras,
        ];
    if (entradas.isEmpty && alSalir == null) return const SizedBox.shrink();
    return PopupMenuButton<VoidCallback>(
      key: const Key('perfil-menu'),
      tooltip: t.perfilUxMenuMas,
      icon: Icon(Icons.more_vert_rounded, color: paleta.sobreCabecera),
      iconSize: 28,
      constraints: const BoxConstraints(minWidth: 200),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(ObjetivoTactilCampo.minimo),
      ),
      color: paleta.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioCampo.media),
      ),
      onSelected: (accion) => accion(),
      itemBuilder: (context) => [
        for (final e in entradas)
          PopupMenuItem<VoidCallback>(
            value: e.alToque,
            child: _Entrada(icono: e.icono, etiqueta: e.etiqueta),
          ),
        if (alSalir != null) ...[
          if (entradas.isNotEmpty) const PopupMenuDivider(),
          PopupMenuItem<VoidCallback>(
            key: const Key('perfil-menu-salir'),
            value: alSalir,
            child: _Entrada(
              icono: Icons.logout_rounded,
              etiqueta: t.ajustesCerrarSesion,
              color: paleta.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({required this.icono, required this.etiqueta, this.color});

  final IconData icono;
  final String etiqueta;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final c = color ?? paleta.texto;
    return Row(
      children: [
        Icon(icono, color: color ?? paleta.acentoTexto),
        const SizedBox(width: EspaciadoCampo.m),
        Flexible(
          child: Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c),
          ),
        ),
      ],
    );
  }
}
