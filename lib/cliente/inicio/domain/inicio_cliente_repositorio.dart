import '../../../nucleo/marketplace/dominio/dominio.dart';

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
/// ni ordena servicios.
class ResumenInicio {
  const ResumenInicio({
    required this.nombre,
    this.empresa,
    this.servicioActivo,
    this.otrosActivos = 0,
    this.porCalificar = const [],
    this.recientes = const [],
    this.avisos = const [],
  });

  /// Primer nombre del cliente, para el saludo.
  final String nombre;
  final String? empresa;

  /// El servicio activo más relevante: el que está en ejecución o, si no
  /// hay ninguno volando, el activo más reciente.
  final Servicio? servicioActivo;

  /// Cuántos servicios activos hay además de [servicioActivo].
  final int otrosActivos;

  /// Completados que el cliente todavía no calificó.
  final List<Servicio> porCalificar;

  /// Últimos servicios cerrados, del más reciente al más antiguo.
  final List<Servicio> recientes;

  final List<AvisoInicio> avisos;

  ResumenInicio sinAviso(String id) => ResumenInicio(
    nombre: nombre,
    empresa: empresa,
    servicioActivo: servicioActivo,
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
