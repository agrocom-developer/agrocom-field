import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/componentes/componentes_campo.dart';
import '../../ui/tokens_campo.dart';
import '../permiso_app.dart';
import '../permisos_servicio.dart';

/// Se asegura de que [permiso] esté concedido justo antes de la actividad que
/// lo usa (abrir la cámara, centrar el mapa). Devuelve si se puede seguir.
///
/// Flujo: si ya está concedido (o no hace falta) sigue sin molestar. Si no,
/// explica para qué se necesita y recién entonces muestra el aviso del
/// sistema. Si la persona lo niega, explica qué pierde y cómo seguir; si el
/// sistema ya no deja preguntar, ofrece abrir los ajustes del teléfono.
Future<bool> asegurarPermiso(
  BuildContext context,
  PermisoApp permiso, {
  PermisosServicio? servicio,
}) async {
  final permisos = servicio ?? PermisosServicio.instancia;
  final actual = await permisos.estado(permiso);
  if (actual.permite) return true;
  if (!context.mounted) return false;

  if (actual == EstadoPermiso.denegadoParaSiempre ||
      actual == EstadoPermiso.restringido) {
    await _hojaBloqueado(context, permiso, permisos);
    return false;
  }

  final sigue = await _hojaMotivo(context, permiso);
  if (sigue != true) return false;
  final resultado = await permisos.solicitar(permiso);
  if (resultado.permite) return true;
  if (!context.mounted) return false;
  await _hojaDenegado(context, permiso, permisos, resultado);
  return false;
}

IconData _icono(PermisoApp p) => switch (p) {
  PermisoApp.camara || PermisoApp.fotos => Icons.photo_camera_rounded,
  PermisoApp.ubicacion => Icons.my_location_rounded,
  PermisoApp.notificaciones => Icons.notifications_active_rounded,
};

String _titulo(AppLocalizations t, PermisoApp p) => switch (p) {
  PermisoApp.camara || PermisoApp.fotos => t.permisosCamaraTitulo,
  PermisoApp.ubicacion => t.permisosUbicacionTitulo,
  PermisoApp.notificaciones => t.permisosNotificacionesTitulo,
};

String _motivo(AppLocalizations t, PermisoApp p) => switch (p) {
  PermisoApp.camara || PermisoApp.fotos => t.permisosCamaraMotivo,
  PermisoApp.ubicacion => t.permisosUbicacionMotivo,
  PermisoApp.notificaciones => t.permisosNotificacionesMotivo,
};

String _denegado(AppLocalizations t, PermisoApp p) => switch (p) {
  PermisoApp.camara || PermisoApp.fotos => t.permisosDenegadoCamara,
  PermisoApp.ubicacion => t.permisosDenegadoUbicacion,
  PermisoApp.notificaciones => t.permisosDenegadoNotificaciones,
};

Future<bool?> _hojaMotivo(BuildContext context, PermisoApp permiso) {
  final t = AppLocalizations.of(context);
  return _hoja<bool>(
    context,
    clave: const Key('permiso-motivo'),
    icono: _icono(permiso),
    titulo: _titulo(t, permiso),
    detalle: _motivo(t, permiso),
    acciones: (hoja) => [
      BotonPrimarioCampo(
        key: const Key('permiso-continuar'),
        texto: t.permisosContinuar,
        onPressed: () => Navigator.pop(hoja, true),
      ),
      TextButton(
        key: const Key('permiso-ahora-no'),
        onPressed: () => Navigator.pop(hoja, false),
        child: Text(t.permisosAhoraNo),
      ),
    ],
  );
}

Future<void> _hojaDenegado(
  BuildContext context,
  PermisoApp permiso,
  PermisosServicio permisos,
  EstadoPermiso resultado,
) {
  final t = AppLocalizations.of(context);
  final bloqueado =
      resultado == EstadoPermiso.denegadoParaSiempre ||
      resultado == EstadoPermiso.restringido;
  return _hoja<void>(
    context,
    clave: const Key('permiso-denegado'),
    icono: Icons.block_rounded,
    titulo: t.permisosDenegadoTitulo,
    detalle: bloqueado
        ? '${_denegado(t, permiso)} ${t.permisosBloqueadoDetalle}'
        : _denegado(t, permiso),
    acciones: (hoja) => [
      if (bloqueado)
        BotonPrimarioCampo(
          key: const Key('permiso-abrir-ajustes'),
          texto: t.permisosAbrirAjustes,
          onPressed: () {
            Navigator.pop(hoja);
            permisos.abrirAjustes();
          },
        ),
      TextButton(
        key: const Key('permiso-entendido'),
        onPressed: () => Navigator.pop(hoja),
        child: Text(t.permisosEntendido),
      ),
    ],
  );
}

Future<void> _hojaBloqueado(
  BuildContext context,
  PermisoApp permiso,
  PermisosServicio permisos,
) => _hojaDenegado(
  context,
  permiso,
  permisos,
  EstadoPermiso.denegadoParaSiempre,
);

Future<T?> _hoja<T>(
  BuildContext context, {
  required Key clave,
  required IconData icono,
  required String titulo,
  required String detalle,
  required List<Widget> Function(BuildContext hoja) acciones,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (hoja) {
      final texto = Theme.of(hoja).textTheme;
      return SafeArea(
        child: Padding(
          key: clave,
          padding: const EdgeInsets.fromLTRB(
            EspaciadoCampo.l,
            EspaciadoCampo.s,
            EspaciadoCampo.l,
            EspaciadoCampo.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: IconoBurbujaCampo(icono, tamano: 64)),
              const SizedBox(height: EspaciadoCampo.l),
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: texto.titleLarge,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              ...acciones(hoja),
            ],
          ),
        ),
      );
    },
  );
}
