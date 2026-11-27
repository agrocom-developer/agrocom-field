import 'package:geolocator/geolocator.dart';

/// Una lectura de la ubicación del dispositivo, solo para centrar el mapa.
/// No se guarda en `drift`, en logs ni en analíticas: vive en memoria de la
/// pantalla que la pidió.
abstract interface class UbicacionPuntual {
  static UbicacionPuntual instancia = const UbicacionPuntualGeolocator();

  /// `null` si el servicio está apagado o no se pudo leer a tiempo.
  Future<({double latitud, double longitud})?> obtener();
}

class UbicacionPuntualGeolocator implements UbicacionPuntual {
  const UbicacionPuntualGeolocator();

  @override
  Future<({double latitud, double longitud})?> obtener() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (latitud: p.latitude, longitud: p.longitude);
    } on Object {
      return null;
    }
  }
}
