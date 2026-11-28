import '../../../marketplace/dominio/falla.dart';
import '../domain/datos_personales.dart';
import '../domain/datos_personales_repositorio.dart';

/// Contra la API. El contrato de `agrocom-api` todavía no tiene la edición
/// única ni la solicitud de cambio de datos (ver
/// `docs/gestion/solicitud-api-datos-personales.md`), así que [disponible] es
/// `false` y cualquier llamada falla con un mensaje claro. Cuando el
/// contrato lo publique, esta clase pasa a hablar con `MarketplaceHttp`.
class DatosPersonalesRed implements DatosPersonalesRepositorio {
  const DatosPersonalesRed();

  static const _noDisponible = OperacionRechazada(
    'Esta función todavía no está disponible.',
    codigo: 501,
    motivo: 'no_disponible',
  );

  @override
  bool get disponible => false;

  @override
  Future<EstadoDatosPersonales> cargar() => Future.error(_noDisponible);

  @override
  Future<EstadoDatosPersonales> editarUnaVez(DatosPersonales datos) =>
      Future.error(_noDisponible);

  @override
  Future<SolicitudCambio> solicitarCambio(String motivo) =>
      Future.error(_noDisponible);
}
