import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/boton_principal_marketplace.dart';
import '../../ui/componentes/hoja_inferior_campo.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../domain/permiso.dart';
import 'textos_permiso.dart';

/// Pide un permiso con su explicación previa (ADR 0026): primero la hoja con
/// el motivo y quién ve lo que se captura; solo si la persona continúa, el
/// aviso del sistema. Un permiso denegado para siempre abre la hoja con la
/// salida a los ajustes. «Ahora no» devuelve [ResultadoPermiso.pospuesto] sin
/// molestar al sistema.
Future<ResultadoPermiso> pedirPermisoConExplicacion(
  BuildContext context,
  GestorPermisos gestor,
  PermisoApp permiso,
) {
  return FlujoPermiso(gestor).ejecutar(
    permiso,
    explicar: (p) async =>
        await mostrarHojaInferiorCampo<bool>(
          context: context,
          builder: (_) => HojaExplicacionPermiso(permiso: p),
        ) ??
        false,
    avisarDenegado: (p, {required ajustes}) async =>
        await mostrarHojaInferiorCampo<bool>(
          context: context,
          builder: (_) => HojaPermisoDenegado(permiso: p, conAjustes: ajustes),
        ) ??
        false,
  );
}

class HojaExplicacionPermiso extends StatelessWidget {
  const HojaExplicacionPermiso({required this.permiso, super.key});

  final PermisoApp permiso;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: permiso.titulo(l10n),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Icon(permiso.icono, size: 36, color: paleta.acentoTexto),
          ),
          const SizedBox(height: EspaciadoCampo.m),
          Text(permiso.titulo(l10n), style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.s),
          Text(permiso.motivo(l10n), style: texto.bodyLarge),
          const SizedBox(height: EspaciadoCampo.m),
          Text(
            permiso.quienLoVe(l10n),
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrincipalMarketplace(
            key: const Key('permiso-continuar'),
            texto: l10n.permisosContinuar,
            alto: ObjetivoTactilCampo.guantes,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          TextButton(
            key: const Key('permiso-ahora-no'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.permisosAhoraNo),
          ),
        ],
      ),
    );
  }
}

class HojaPermisoDenegado extends StatelessWidget {
  const HojaPermisoDenegado({
    required this.permiso,
    required this.conAjustes,
    super.key,
  });

  final PermisoApp permiso;

  /// Solo los ajustes del teléfono pueden cambiarlo.
  final bool conAjustes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: l10n.permisosDenegadoTitulo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.block_rounded,
              size: 36,
              color: paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: EspaciadoCampo.m),
          Text(l10n.permisosDenegadoTitulo, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.s),
          Text(permiso.sinPermiso(l10n), style: texto.bodyLarge),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            conAjustes
                ? l10n.permisosDenegadoAjustes
                : l10n.permisosDenegadoReintento,
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          if (conAjustes)
            BotonPrincipalMarketplace(
              key: const Key('permiso-abrir-ajustes'),
              texto: l10n.permisosAbrirAjustes,
              icono: Icons.settings_outlined,
              alto: ObjetivoTactilCampo.guantes,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          TextButton(
            key: const Key('permiso-cerrar'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.permisosCerrar),
          ),
        ],
      ),
    );
  }
}
