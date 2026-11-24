import 'dart:async';

import '../../nucleo/marketplace/demo/datos_demo.dart';
import '../../nucleo/marketplace/dominio/dominio.dart';
import '../acceso/domain/acceso_repositorio.dart';

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

  /// Sesión del cliente en la demo; `null` mientras nadie haya entrado.
  SesionCliente? sesion;

  /// Actas ya firmadas u observadas en esta sesión, por servicio.
  final actas = <String, ActaConformidad>{};

  /// Calificaciones que el cliente emitió en esta sesión, por servicio.
  final calificaciones = <String, CalificacionEmitida>{};

  /// Problemas reportados en esta sesión, por servicio (uno por servicio).
  final problemas = <String, ProblemaReportado>{};

  /// Simula la falta de red: con `true`, los repositorios demo lanzan
  /// [SinConexion]. Sirve para ver y probar los estados sin conexión.
  bool sinRed = false;

  /// Lanza [SinConexion] si la demo está simulando la falta de red.
  void exigirRed() {
    if (sinRed) throw const SinConexion();
  }

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
