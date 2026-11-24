import '../../solicitudes/domain/solicitud.dart';
import 'inicio_cliente_repositorio.dart';

/// Arma el resumen del inicio a partir de la lista de solicitudes (de la más
/// reciente a la más antigua). Regla pura: la comparten el repositorio demo y
/// el de red.
abstract final class ReglasInicioCliente {
  static const int maximoRecientes = 3;

  /// Qué solicitud activa se destaca: la que espera una decisión del cliente
  /// o la que está en marcha pesa más que una que solo espera ofertas.
  static int _peso(EstadoSolicitud e) => switch (e) {
    EstadoSolicitud.conOfertas => 0,
    EstadoSolicitud.enEjecucion => 1,
    EstadoSolicitud.adjudicada => 2,
    EstadoSolicitud.finalizada => 3,
    EstadoSolicitud.disputada => 4,
    _ => 5,
  };

  static ResumenInicio resumir({
    required String nombre,
    required List<Solicitud> solicitudes,
    String? empresa,
    List<AvisoInicio> avisos = const [],
  }) {
    // Las finalizadas sin calificar van en su propio bloque.
    final activas = solicitudes
        .where(
          (s) =>
              s.estado.activa &&
              !(s.estado == EstadoSolicitud.finalizada &&
                  s.puntajeDelCliente == null),
        )
        .toList();
    final ordenadas = [...activas]
      ..sort((a, b) => _peso(a.estado).compareTo(_peso(b.estado)));
    return ResumenInicio(
      nombre: nombre,
      empresa: empresa,
      solicitudActiva: ordenadas.isEmpty ? null : ordenadas.first,
      otrosActivos: ordenadas.isEmpty ? 0 : ordenadas.length - 1,
      porCalificar: solicitudes
          .where(
            (s) =>
                s.estado == EstadoSolicitud.finalizada &&
                s.puntajeDelCliente == null,
          )
          .toList(),
      recientes: solicitudes
          .where((s) => s.estado == EstadoSolicitud.calificada)
          .take(maximoRecientes)
          .toList(),
      avisos: avisos,
    );
  }
}
