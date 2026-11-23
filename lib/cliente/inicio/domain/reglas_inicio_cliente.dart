import '../../../nucleo/marketplace/dominio/dominio.dart';
import 'inicio_cliente_repositorio.dart';

/// Arma el resumen del inicio a partir de la lista de servicios (del más
/// reciente al más antiguo). Regla pura: la comparten el repositorio demo y
/// el de red.
abstract final class ReglasInicioCliente {
  static const int maximoRecientes = 3;

  static ResumenInicio resumir({
    required String nombre,
    required List<Servicio> servicios,
    String? empresa,
    List<AvisoInicio> avisos = const [],
  }) {
    final activos = servicios.where((s) => s.estado.activo).toList();
    Servicio? principal;
    for (final s in activos) {
      if (s.estado == EstadoServicio.enEjecucion) {
        principal = s;
        break;
      }
    }
    principal ??= activos.isEmpty ? null : activos.first;
    final completados = servicios.where(
      (s) => s.estado == EstadoServicio.completado,
    );
    return ResumenInicio(
      nombre: nombre,
      empresa: empresa,
      servicioActivo: principal,
      otrosActivos: activos.isEmpty ? 0 : activos.length - 1,
      porCalificar: completados
          .where((s) => s.puntajeDelCliente == null)
          .toList(),
      recientes: completados
          .where((s) => s.puntajeDelCliente != null)
          .take(maximoRecientes)
          .toList(),
      avisos: avisos,
    );
  }
}
