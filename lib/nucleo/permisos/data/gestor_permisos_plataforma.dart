import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/permiso.dart';

/// Permisos reales del teléfono con los plugins que la app ya usa:
/// `geolocator` (ubicación y ajustes), `flutter_local_notifications` (avisos)
/// y, para la cámara, el propio `image_picker`, que pide el permiso al abrirla
/// (ADR 0026). Sin dependencia nueva.
class GestorPermisosPlataforma implements GestorPermisos {
  GestorPermisosPlataforma([FlutterLocalNotificationsPlugin? notificaciones])
    : _notificaciones = notificaciones ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificaciones;
  final Set<PermisoApp> _denegadosParaSiempre = {};

  @override
  Future<EstadoPermiso> estado(PermisoApp permiso) async => switch (permiso) {
    PermisoApp.camara =>
      _denegadosParaSiempre.contains(PermisoApp.camara)
          ? EstadoPermiso.denegadoParaSiempre
          : EstadoPermiso.sinPreguntar,
    PermisoApp.ubicacion => await _ubicacion(
      await Geolocator.checkPermission(),
    ),
    PermisoApp.notificaciones => await _estadoNotificaciones(),
  };

  @override
  Future<EstadoPermiso> pedir(PermisoApp permiso) async => switch (permiso) {
    PermisoApp.camara => EstadoPermiso.sinPreguntar,
    PermisoApp.ubicacion => await _ubicacion(
      await Geolocator.requestPermission(),
    ),
    PermisoApp.notificaciones => await _pedirNotificaciones(),
  };

  @override
  Future<void> abrirAjustes(PermisoApp permiso) async {
    if (permiso == PermisoApp.ubicacion &&
        !await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    await Geolocator.openAppSettings();
  }

  @override
  void registrarDenegadoParaSiempre(PermisoApp permiso) =>
      _denegadosParaSiempre.add(permiso);

  Future<EstadoPermiso> _ubicacion(LocationPermission p) async {
    final concedido =
        p == LocationPermission.always || p == LocationPermission.whileInUse;
    if (concedido && !await Geolocator.isLocationServiceEnabled()) {
      return EstadoPermiso.servicioApagado;
    }
    return switch (p) {
      LocationPermission.always ||
      LocationPermission.whileInUse => EstadoPermiso.concedido,
      LocationPermission.deniedForever => EstadoPermiso.denegadoParaSiempre,
      LocationPermission.denied => EstadoPermiso.sinPreguntar,
      LocationPermission.unableToDetermine => EstadoPermiso.denegado,
    };
  }

  Future<EstadoPermiso> _estadoNotificaciones() async {
    final android = _notificaciones
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() == true
          ? EstadoPermiso.concedido
          : EstadoPermiso.sinPreguntar;
    }
    final ios = _notificaciones
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final permisos = await ios?.checkPermissions();
    if (permisos == null) return EstadoPermiso.sinPreguntar;
    return permisos.isEnabled
        ? EstadoPermiso.concedido
        : EstadoPermiso.sinPreguntar;
  }

  Future<EstadoPermiso> _pedirNotificaciones() async {
    final android = _notificaciones
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? concedido;
    if (android != null) {
      concedido = await android.requestNotificationsPermission();
    } else {
      concedido = await _notificaciones
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    // El sistema solo deja preguntar una vez (o dos en Android): un «no»
    // se trata como definitivo y se guía a los ajustes.
    return concedido == true
        ? EstadoPermiso.concedido
        : EstadoPermiso.denegadoParaSiempre;
  }
}
