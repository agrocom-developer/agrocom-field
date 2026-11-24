import '../../solicitudes/domain/solicitud.dart';

enum TonoAvisoInicio { info, alerta }

/// Aviso breve del inicio: algo que al cliente le conviene saber hoy.
class AvisoInicio {
  const AvisoInicio({
    required this.id,
    required this.titulo,
    required this.detalle,
    this.tono = TonoAvisoInicio.info,
  });

  final String id;
  final String titulo;
  final String detalle;
  final TonoAvisoInicio tono;
}

/// Lo que muestra el inicio del cliente, ya resuelto: la pantalla no filtra
/// ni ordena solicitudes.
class ResumenInicio {
  const ResumenInicio({
    required this.nombre,
    this.empresa,
    this.solicitudActiva,
    this.otrosActivos = 0,
    this.porCalificar = const [],
    this.recientes = const [],
    this.avisos = const [],
  });

  /// Primer nombre del cliente, para el saludo.
  final String nombre;
  final String? empresa;

  /// La solicitud activa más relevante: la que tiene ofertas esperando, la
  /// que está en ejecución o, si no hay, la activa más reciente.
  final Solicitud? solicitudActiva;

  /// Cuántas solicitudes activas hay además de [solicitudActiva].
  final int otrosActivos;

  /// Finalizadas que el cliente todavía no calificó.
  final List<Solicitud> porCalificar;

  /// Últimas solicitudes cerradas, de la más reciente a la más antigua.
  final List<Solicitud> recientes;

  final List<AvisoInicio> avisos;

  ResumenInicio sinAviso(String id) => ResumenInicio(
    nombre: nombre,
    empresa: empresa,
    solicitudActiva: solicitudActiva,
    otrosActivos: otrosActivos,
    porCalificar: porCalificar,
    recientes: recientes,
    avisos: [
      for (final a in avisos)
        if (a.id != id) a,
    ],
  );
}

/// La red no respondió al cargar el inicio.
class InicioSinConexion implements Exception {
  const InicioSinConexion();
}

/// Resumen del inicio del cliente. Online-first (ADR 0009): el repositorio
/// de red lee de la API con caché de lectura.
abstract interface class InicioClienteRepositorio {
  /// Emite el resumen y vuelve a emitir cuando algo cambia (solicitud
  /// nueva, avance del servicio, calificación). Un error de red llega como
  /// [InicioSinConexion].
  Stream<ResumenInicio> observar();
}
