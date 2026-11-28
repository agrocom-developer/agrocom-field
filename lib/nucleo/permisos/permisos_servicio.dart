import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permiso_app.dart';

/// Consulta y solicita permisos del sistema. Abstracto para fakear en las
/// pruebas sin canal de plataforma, igual que `SelectorFoto` y
/// `NotificadorLocal`.
abstract interface class PermisosServicio {
  /// Servicio que usan las pantallas. Las pruebas lo reemplazan por un
  /// [PermisosServicioFalso].
  static PermisosServicio instancia = const PermisosServicioReal();

  Future<EstadoPermiso> estado(PermisoApp permiso);

  /// Muestra el aviso del sistema. Solo debe llamarse tras explicar el motivo.
  Future<EstadoPermiso> solicitar(PermisoApp permiso);

  /// Abre los ajustes de la app en el teléfono.
  Future<bool> abrirAjustes();
}

/// Implementación con `permission_handler`.
///
/// Si el canal de plataforma no responde (pruebas de widget, plataforma sin
/// el plugin) devuelve [EstadoPermiso.concedido] y deja que la API nativa que
/// se usa después (cámara, ubicación) haga su propia verificación.
class PermisosServicioReal implements PermisosServicio {
  const PermisosServicioReal();

  Permission? _de(PermisoApp permiso) => switch (permiso) {
    PermisoApp.camara => Permission.camera,
    PermisoApp.ubicacion => Permission.locationWhenInUse,
    PermisoApp.notificaciones => Permission.notification,
    PermisoApp.fotos => null,
  };

  static EstadoPermiso traducir(PermissionStatus s) => switch (s) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => EstadoPermiso.concedido,
    PermissionStatus.denied => EstadoPermiso.denegado,
    PermissionStatus.permanentlyDenied => EstadoPermiso.denegadoParaSiempre,
    PermissionStatus.restricted => EstadoPermiso.restringido,
  };

  @override
  Future<EstadoPermiso> estado(PermisoApp permiso) async {
    final p = _de(permiso);
    if (p == null) return EstadoPermiso.noRequerido;
    try {
      return traducir(await p.status);
    } on Object {
      return EstadoPermiso.concedido;
    }
  }

  @override
  Future<EstadoPermiso> solicitar(PermisoApp permiso) async {
    final p = _de(permiso);
    if (p == null) return EstadoPermiso.noRequerido;
    try {
      return traducir(await p.request());
    } on Object {
      return EstadoPermiso.concedido;
    }
  }

  @override
  Future<bool> abrirAjustes() async {
    try {
      return await openAppSettings();
    } on Object {
      return false;
    }
  }
}

/// Permisos en memoria para pruebas y la demo sin plataforma: cada permiso
/// arranca en [inicial] y `solicitar` responde [alSolicitar].
@visibleForTesting
class PermisosServicioFalso implements PermisosServicio {
  PermisosServicioFalso({
    this.inicial = EstadoPermiso.denegado,
    this.alSolicitar = EstadoPermiso.concedido,
  });

  final EstadoPermiso inicial;
  final EstadoPermiso alSolicitar;

  final Map<PermisoApp, EstadoPermiso> _estados = {};

  /// Qué permisos se solicitaron al sistema, en orden.
  final solicitados = <PermisoApp>[];
  int ajustesAbiertos = 0;

  @override
  Future<EstadoPermiso> estado(PermisoApp permiso) async =>
      permiso == PermisoApp.fotos
      ? EstadoPermiso.noRequerido
      : _estados[permiso] ?? inicial;

  @override
  Future<EstadoPermiso> solicitar(PermisoApp permiso) async {
    solicitados.add(permiso);
    return _estados[permiso] = alSolicitar;
  }

  @override
  Future<bool> abrirAjustes() async {
    ajustesAbiertos++;
    return true;
  }
}
