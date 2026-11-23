import 'dart:async';

import '../../nucleo/marketplace/demo/datos_demo.dart';
import '../../nucleo/marketplace/dominio/dominio.dart';

/// Estado en memoria del flavor cliente en modo demo: los repositorios fake
/// de cada feature lo comparten para que una solicitud nueva aparezca en el
/// historial y una calificación quede guardada. Se pierde al cerrar la app.
class AlmacenDemoCliente {
  AlmacenDemoCliente({DatosDemo? datos}) : datos = datos ?? DatosDemo() {
    _servicios = List.of(this.datos.servicios);
  }

  final DatosDemo datos;
  late List<Servicio> _servicios;
  final _cambios = StreamController<List<Servicio>>.broadcast();
  final _porClave = <String, Servicio>{};

  List<Servicio> get servicios => List.unmodifiable(_servicios);

  Stream<List<Servicio>> observar() async* {
    yield servicios;
    yield* _cambios.stream;
  }

  Servicio? porId(String id) {
    for (final s in _servicios) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Agrega el servicio de una solicitud; la misma clave devuelve el mismo
  /// servicio (idempotencia).
  Servicio agregarSolicitud(SolicitudServicio solicitud, Servicio nuevo) {
    final previo = _porClave[solicitud.claveIdempotencia];
    if (previo != null) return previo;
    _porClave[solicitud.claveIdempotencia] = nuevo;
    _servicios = [nuevo, ..._servicios];
    _cambios.add(servicios);
    return nuevo;
  }

  void reemplazar(Servicio actualizado) {
    _servicios = [
      for (final s in _servicios) s.id == actualizado.id ? actualizado : s,
    ];
    _cambios.add(servicios);
  }

  void cerrar() => _cambios.close();
}
