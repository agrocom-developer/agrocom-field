import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/fila_accion_campo.dart';
import '../../negociacion/presentation/avisos_pantalla.dart';

/// Las filas de cuenta que van en el perfil de `piloto`: los avisos (solo con
/// negociación) y cerrar sesión (solo en la app real). El tema vive en
/// Ajustes → Apariencia.
List<Widget> extrasDePerfil(
  BuildContext context, {
  required bool conAvisos,
  VoidCallback? alSalir,
}) {
  final t = AppLocalizations.of(context);
  return [
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
  Widget build(BuildContext context) => FilaAccionCampo(
    clave: clave,
    icono: icono,
    titulo: titulo,
    detalle: detalle,
    alToque: alToque,
  );
}
