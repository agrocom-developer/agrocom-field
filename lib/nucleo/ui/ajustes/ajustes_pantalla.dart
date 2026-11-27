import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/superficie_marketplace.dart';
import '../componentes/fila_accion_campo.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'apariencia_pantalla.dart';

/// Ajustes de la app, en grupos de tarjetas con filas separadas por un
/// divisor fino: primero Apariencia y las [filas] propias del flavor
/// (p. ej. Notificaciones), luego Cuenta con Cerrar sesión (solo si hay
/// [alSalir]; pide confirmación). Las [filas] deben ser [FilaAjusteCampo].
class AjustesPantalla extends StatelessWidget {
  const AjustesPantalla({this.filas = const [], this.alSalir, super.key});

  final List<Widget> filas;
  final VoidCallback? alSalir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.ajustesTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          _Grupo(
            children: [
              FilaAjusteCampo(
                clave: const Key('ajustes-apariencia'),
                icono: Icons.palette_outlined,
                titulo: t.ajustesApariencia,
                detalle: t.ajustesAparienciaDetalle,
                alToque: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AparienciaPantalla(),
                  ),
                ),
              ),
              ...filas,
            ],
          ),
          if (alSalir != null) ...[
            const SizedBox(height: EspaciadoCampo.xl),
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
                child: Text(
                  t.ajustesCuenta,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _Grupo(
              children: [
                FilaAjusteCampo(
                  clave: const Key('ajustes-cerrar-sesion'),
                  icono: Icons.logout_rounded,
                  titulo: t.ajustesCerrarSesion,
                  detalle: t.ajustesCerrarSesionDetalle,
                  alToque: () => _confirmarSalida(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.ajustesCerrarSesionPregunta),
        content: Text(t.ajustesCerrarSesionAviso),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.ajustesCancelar),
          ),
          TextButton(
            key: const Key('ajustes-confirmar-salida'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.paleta.error),
            child: Text(t.ajustesCerrarSesion),
          ),
        ],
      ),
    );
    if (ok == true) alSalir?.call();
  }
}

/// Tarjeta con filas separadas por un divisor fino.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final borde = context.paleta.borde;
    return SuperficieMarketplace(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: borde),
            children[i],
          ],
        ],
      ),
    );
  }
}
