import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/permiso.dart';

/// Textos y símbolo de cada permiso. El `switch` es exhaustivo: un permiso
/// nuevo no compila hasta tener su explicación.
extension TextosPermiso on PermisoApp {
  IconData get icono => switch (this) {
    PermisoApp.camara => Icons.photo_camera_outlined,
    PermisoApp.ubicacion => Icons.location_on_outlined,
    PermisoApp.notificaciones => Icons.notifications_active_outlined,
  };

  String titulo(AppLocalizations l10n) => switch (this) {
    PermisoApp.camara => l10n.permisosCamaraTitulo,
    PermisoApp.ubicacion => l10n.permisosUbicacionTitulo,
    PermisoApp.notificaciones => l10n.permisosNotificacionesTitulo,
  };

  String motivo(AppLocalizations l10n) => switch (this) {
    PermisoApp.camara => l10n.permisosCamaraMotivo,
    PermisoApp.ubicacion => l10n.permisosUbicacionMotivo,
    PermisoApp.notificaciones => l10n.permisosNotificacionesMotivo,
  };

  String quienLoVe(AppLocalizations l10n) => switch (this) {
    PermisoApp.camara => l10n.permisosCamaraQuienVe,
    PermisoApp.ubicacion => l10n.permisosUbicacionQuienVe,
    PermisoApp.notificaciones => l10n.permisosNotificacionesQuienVe,
  };

  /// Lo que deja de funcionar sin el permiso, para el estado «denegado».
  String sinPermiso(AppLocalizations l10n) => switch (this) {
    PermisoApp.camara => l10n.permisosCamaraSin,
    PermisoApp.ubicacion => l10n.permisosUbicacionSin,
    PermisoApp.notificaciones => l10n.permisosNotificacionesSin,
  };
}
