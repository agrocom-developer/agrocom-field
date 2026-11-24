import 'package:geolocator/geolocator.dart';

import '../../../../api/marketplace_http.dart';
import '../../../dominio/dominio.dart';
import '../domain/ejecucion.dart';

/// Ubicación del dispositivo con `geolocator`. Solo se consulta con la
/// pantalla de un servicio en ejecución abierta: no hay seguimiento en
/// segundo plano ni permiso permanente.
class ServicioUbicacionGeolocator implements ServicioUbicacion {
  PermisoUbicacion _traducir(LocationPermission p, bool servicio) {
    if (!servicio) return PermisoUbicacion.servicioApagado;
    return switch (p) {
      LocationPermission.always ||
      LocationPermission.whileInUse => PermisoUbicacion.concedido,
      LocationPermission.deniedForever => PermisoUbicacion.denegadoParaSiempre,
      _ => PermisoUbicacion.denegado,
    };
  }

  @override
  Future<PermisoUbicacion> estado() async => _traducir(
    await Geolocator.checkPermission(),
    await Geolocator.isLocationServiceEnabled(),
  );

  @override
  Future<PermisoUbicacion> pedir() async => _traducir(
    await Geolocator.requestPermission(),
    await Geolocator.isLocationServiceEnabled(),
  );

  @override
  Future<GeoPunto?> actual() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPunto(p.latitude, p.longitude);
    } on Object {
      return null;
    }
  }
}

/// `PUT /api/ubicacion`: reemplaza la última posición del piloto. El
/// servidor la borra al finalizar o cancelar y no la guarda en historial ni
/// en logs.
class UbicacionRed implements UbicacionRepositorio {
  UbicacionRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<void> publicar(
    int solicitudId,
    GeoPunto punto, {
    double? precisionM,
  }) async {
    await _http.guardar(
      '/api/ubicacion',
      datos: {
        'solicitud_id': solicitudId,
        'latitud': punto.latitud,
        'longitud': punto.longitud,
        'precision_m': ?precisionM,
        'capturado_en': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
