/// Los permisos del sistema que piden las apps. Cada uno se explica antes de
/// pedirlo (ADR 0026).
enum PermisoApp {
  /// Selfie, documentos y fotos de avance.
  camara,

  /// Última posición del piloto durante un servicio y auxilio.
  ubicacion,

  /// Avisos de solicitudes nuevas y de la negociación.
  notificaciones,
}

enum EstadoPermiso {
  /// Nunca se pidió: el sistema todavía puede mostrar su aviso.
  sinPreguntar,
  concedido,

  /// Dijo «no», pero el sistema aún permite volver a preguntar.
  denegado,

  /// Solo se cambia desde los ajustes del teléfono.
  denegadoParaSiempre,

  /// El permiso está concedido pero el servicio del teléfono está apagado
  /// (por ejemplo, el GPS).
  servicioApagado,
}

/// Lo que pasó al recorrer el flujo «explicar, pedir, guiar a ajustes».
enum ResultadoPermiso {
  /// Se puede usar la función.
  concedido,

  /// La persona eligió «Ahora no» en la explicación: no se preguntó al sistema.
  pospuesto,

  /// El sistema dijo que no; se puede volver a intentar.
  denegado,

  /// Solo los ajustes lo cambian; la hoja ya ofreció abrirlos.
  denegadoParaSiempre,
}

/// Consulta y pide permisos al sistema operativo. Abstracta para fakear en
/// pruebas sin canal de plataforma (mismo patrón que `NotificadorLocal`).
abstract interface class GestorPermisos {
  Future<EstadoPermiso> estado(PermisoApp permiso);

  /// Muestra el aviso del sistema. No explica nada: eso lo hace [FlujoPermiso]
  /// antes de llamarlo. En la cámara, que se pide al abrirla, devuelve
  /// [EstadoPermiso.sinPreguntar] y la captura es la que dispara el aviso.
  Future<EstadoPermiso> pedir(PermisoApp permiso);

  /// Abre los ajustes de la app (o de ubicación, si el servicio está apagado).
  Future<void> abrirAjustes(PermisoApp permiso);

  /// La captura reveló que el sistema negó la cámara.
  void registrarDenegadoParaSiempre(PermisoApp permiso);
}

/// La explicación previa y la salida a ajustes, sin widgets: la pantalla
/// implementa los dos pasos visibles ([explicar] y [avisarDenegado]).
class FlujoPermiso {
  const FlujoPermiso(this._gestor);

  final GestorPermisos _gestor;

  /// [explicar] muestra el motivo y devuelve si la persona continúa.
  /// [avisarDenegado] muestra el estado «denegado» con la salida a ajustes y
  /// devuelve si la persona pidió abrirlos.
  Future<ResultadoPermiso> ejecutar(
    PermisoApp permiso, {
    required Future<bool> Function(PermisoApp permiso) explicar,
    required Future<bool> Function(PermisoApp permiso, {required bool ajustes})
    avisarDenegado,
  }) async {
    final estado = await _gestor.estado(permiso);
    switch (estado) {
      case EstadoPermiso.concedido:
        return ResultadoPermiso.concedido;
      case EstadoPermiso.denegadoParaSiempre:
      case EstadoPermiso.servicioApagado:
        if (await avisarDenegado(permiso, ajustes: true)) {
          await _gestor.abrirAjustes(permiso);
        }
        return ResultadoPermiso.denegadoParaSiempre;
      case EstadoPermiso.sinPreguntar:
      case EstadoPermiso.denegado:
        break;
    }

    if (!await explicar(permiso)) return ResultadoPermiso.pospuesto;

    final nuevo = await _gestor.pedir(permiso);
    switch (nuevo) {
      case EstadoPermiso.concedido:
      case EstadoPermiso.sinPreguntar:
        // La cámara se concede al abrirla: se sigue y la captura avisa si no.
        return ResultadoPermiso.concedido;
      case EstadoPermiso.denegado:
        await avisarDenegado(permiso, ajustes: false);
        return ResultadoPermiso.denegado;
      case EstadoPermiso.denegadoParaSiempre:
      case EstadoPermiso.servicioApagado:
        if (await avisarDenegado(permiso, ajustes: true)) {
          await _gestor.abrirAjustes(permiso);
        }
        return ResultadoPermiso.denegadoParaSiempre;
    }
  }
}

/// Gestor en memoria para pruebas y modo demo: cada permiso tiene un estado
/// y [pedir] lo resuelve con lo que diga [respuestas].
class GestorPermisosEnMemoria implements GestorPermisos {
  GestorPermisosEnMemoria({
    Map<PermisoApp, EstadoPermiso>? estados,
    Map<PermisoApp, EstadoPermiso>? respuestas,
  }) : _estados = {...?estados},
       _respuestas = {...?respuestas};

  final Map<PermisoApp, EstadoPermiso> _estados;
  final Map<PermisoApp, EstadoPermiso> _respuestas;

  final List<PermisoApp> pedidos = [];
  final List<PermisoApp> ajustesAbiertos = [];

  @override
  Future<EstadoPermiso> estado(PermisoApp permiso) async =>
      _estados[permiso] ?? EstadoPermiso.sinPreguntar;

  @override
  Future<EstadoPermiso> pedir(PermisoApp permiso) async {
    pedidos.add(permiso);
    final resultado = _respuestas[permiso] ?? EstadoPermiso.concedido;
    _estados[permiso] = resultado;
    return resultado;
  }

  @override
  Future<void> abrirAjustes(PermisoApp permiso) async =>
      ajustesAbiertos.add(permiso);

  @override
  void registrarDenegadoParaSiempre(PermisoApp permiso) =>
      _estados[permiso] = EstadoPermiso.denegadoParaSiempre;
}
