import '../../../marketplace/dominio/falla.dart';
import '../domain/datos_personales.dart';
import '../domain/datos_personales_repositorio.dart';

/// En memoria, para el modo demo y las pruebas. Reproduce la regla del
/// servidor: una edición libre y, después, solo solicitudes de cambio (una
/// abierta a la vez).
class DatosPersonalesDemo implements DatosPersonalesRepositorio {
  DatosPersonalesDemo(
    this._datos, {
    bool puedeEditar = true,
    this.latencia = const Duration(milliseconds: 500),
    DateTime Function() reloj = DateTime.now,
  }) : _puedeEditar = puedeEditar,
       _reloj = reloj;

  DatosPersonales _datos;
  bool _puedeEditar;
  SolicitudCambio? _solicitud;
  final Duration latencia;
  final DateTime Function() _reloj;

  EstadoDatosPersonales get _estado => EstadoDatosPersonales(
    datos: _datos,
    puedeEditar: _puedeEditar,
    solicitud: _solicitud,
  );

  Future<void> _esperar() => Future<void>.delayed(latencia);

  @override
  bool get disponible => true;

  @override
  Future<EstadoDatosPersonales> cargar() async {
    await _esperar();
    return _estado;
  }

  @override
  Future<EstadoDatosPersonales> editarUnaVez(DatosPersonales datos) async {
    await _esperar();
    if (!_puedeEditar) {
      throw const OperacionRechazada(
        'Ya usaste tu edición.',
        codigo: 409,
        motivo: 'edicion_agotada',
      );
    }
    _datos = datos;
    _puedeEditar = false;
    return _estado;
  }

  @override
  Future<SolicitudCambio> solicitarCambio(String motivo) async {
    await _esperar();
    if (_puedeEditar) {
      throw const OperacionRechazada(
        'Todavía puedes editar tus datos.',
        codigo: 409,
        motivo: 'edicion_disponible',
      );
    }
    if (_solicitud?.abierta ?? false) {
      throw const OperacionRechazada(
        'Ya tienes una solicitud en revisión.',
        codigo: 409,
        motivo: 'solicitud_abierta',
      );
    }
    return _solicitud = SolicitudCambio(
      motivo: motivo,
      estado: EstadoSolicitudCambio.pendiente,
      creada: _reloj(),
    );
  }
}
