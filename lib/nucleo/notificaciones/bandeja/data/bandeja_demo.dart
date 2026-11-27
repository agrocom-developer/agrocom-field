import '../domain/bandeja_repositorio.dart';
import '../domain/notificacion.dart';

/// Bandeja en memoria del modo demo (ADR 0010): mensajes entre cliente y
/// piloto y avisos del sistema, con fechas relativas a [ahora] para que los
/// grupos «Hoy», «Ayer» y «Antes» siempre se vean.
class BandejaDemo implements BandejaRepositorio {
  BandejaDemo({
    DateTime Function()? reloj,
    this.latencia = const Duration(milliseconds: 400),
  }) : _reloj = reloj ?? DateTime.now {
    final ahora = _reloj();
    _avisos = [
      Notificacion(
        id: 1,
        origen: const OrigenPersona('Mamani Agroservicios'),
        titulo: 'Mamani Agroservicios',
        cuerpo:
            'Buen día, llego al lote a las 7:00. ¿Hay acceso para la camioneta?',
        fecha: ahora.subtract(const Duration(minutes: 18)),
        destino: const DestinoNotificacion('solicitud', 42),
      ),
      Notificacion(
        id: 2,
        origen: const OrigenSistema(),
        titulo: 'Tu solicitud recibió 3 ofertas',
        cuerpo: 'Compáralas y elige la que más te convenga.',
        fecha: ahora.subtract(const Duration(hours: 2)),
        destino: const DestinoNotificacion('solicitud', 42),
      ),
      Notificacion(
        id: 3,
        origen: const OrigenPersona('Rosario Antelo'),
        titulo: 'Rosario Antelo',
        cuerpo: 'Gracias por la contraoferta, la acepto. Nos vemos el viernes.',
        fecha: ahora.subtract(const Duration(hours: 5)),
        leida: true,
        destino: const DestinoNotificacion('solicitud', 41),
      ),
      Notificacion(
        id: 4,
        origen: const OrigenSistema(),
        titulo: 'Tu cuenta fue aprobada',
        cuerpo: 'Ya puedes ver el mapa de solicitudes y ofertar.',
        fecha: ahora.subtract(const Duration(days: 1, hours: 3)),
        leida: true,
        destino: const DestinoNotificacion('proveedor', 12),
      ),
      Notificacion(
        id: 5,
        origen: const OrigenPersona('Hugo Antelo'),
        titulo: 'Hugo Antelo',
        cuerpo:
            'Subí las fotos del avance. Quedan 40 hectáreas para terminar el lote.',
        fecha: ahora.subtract(const Duration(days: 1, hours: 8)),
        destino: const DestinoNotificacion('solicitud', 40),
      ),
      Notificacion(
        id: 6,
        origen: const OrigenSistema(),
        titulo: 'Servicio finalizado: Cuatro Cañadas',
        cuerpo: 'El precio final es de Bs 18.400. Págalo fuera de la app.',
        fecha: ahora.subtract(const Duration(days: 4)),
        leida: true,
        destino: const DestinoNotificacion('solicitud', 38),
      ),
      Notificacion(
        id: 7,
        origen: const OrigenSistema(),
        titulo: 'Calificaron tu trabajo',
        cuerpo: 'Recibiste 5 estrellas por el servicio en Las Palmas.',
        fecha: ahora.subtract(const Duration(days: 6)),
        leida: true,
        destino: const DestinoNotificacion('solicitud', 35),
      ),
    ];
  }

  final DateTime Function() _reloj;
  final Duration latencia;
  late List<Notificacion> _avisos;

  @override
  Future<List<Notificacion>> listar() async {
    await Future<void>.delayed(latencia);
    final orden = [..._avisos]
      ..sort((a, b) {
        if (a.leida != b.leida) return a.leida ? 1 : -1;
        return b.fecha.compareTo(a.fecha);
      });
    return orden;
  }

  @override
  Future<void> marcarLeida(int id) async {
    _avisos = [for (final n in _avisos) n.id == id ? n.comoLeida() : n];
  }

  @override
  Future<void> marcarTodasLeidas() async {
    _avisos = [for (final n in _avisos) n.comoLeida()];
  }
}
