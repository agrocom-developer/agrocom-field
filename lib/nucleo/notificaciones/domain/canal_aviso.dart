/// Qué tan fuerte avisa un canal: define la importancia del canal de Android
/// y si la categoría de iOS interrumpe.
enum NivelAviso { alto, medio }

/// Los canales de aviso de las dos apps. Cada tipo de aviso del servidor
/// (`GET /api/notificaciones`, campo `tipo`) pertenece a un solo canal, y cada
/// canal tiene su canal de Android, su categoría de iOS y sus preferencias.
enum CanalAviso {
  /// Solicitudes nuevas que llegan por oleadas al proveedor.
  nuevasSolicitudes('nuevas_solicitudes', NivelAviso.alto, soloProveedor: true),

  /// Ofertas, contraofertas y la adjudicación.
  ofertas('ofertas', NivelAviso.alto),

  /// Mensajes del chat con la otra parte.
  mensajes('mensajes', NivelAviso.alto),

  /// El servicio ya adjudicado: inicio, avance, cierre y precio final.
  ejecucion('ejecucion', NivelAviso.medio),

  /// Cuenta, documentos, calificaciones y avisos del sistema. Son
  /// obligatorios: no se apagan.
  cuenta('cuenta', NivelAviso.medio, obligatorio: true);

  const CanalAviso(
    this.codigo,
    this.nivel, {
    this.soloProveedor = false,
    this.obligatorio = false,
  });

  /// Identificador estable: es el id del canal de Android y de la categoría
  /// de iOS, y la clave de sus preferencias.
  final String codigo;
  final NivelAviso nivel;

  /// Solo lo reciben las cuentas de proveedor.
  final bool soloProveedor;

  /// No se puede apagar ni silenciar por horario.
  final bool obligatorio;

  /// Canal al que pertenece un tipo de aviso del servidor. Un tipo que la app
  /// no conoce cae en [cuenta]: se muestra, nunca se pierde.
  static CanalAviso deTipo(String tipo) => switch (tipo) {
    'nueva_solicitud_abierta' => nuevasSolicitudes,
    'oferta_creada' ||
    'oferta_recibida' ||
    'oferta_vencida' ||
    'oferta_retirada' ||
    'precio_cambiado' ||
    'solicitud_asignada' ||
    'solicitud_reasignada' ||
    'solicitud_adjudicada' ||
    'solicitud_reabierta' ||
    'solicitud_sin_proveedor' => ofertas,
    'mensaje_nuevo' => mensajes,
    'ejecucion_iniciada' ||
    'avance_registrado' ||
    'solicitud_finalizada' ||
    'solicitud_ejecutada' ||
    'solicitud_completada' ||
    'precio_final_confirmado' ||
    'equipo_en_camino' ||
    'trabajo_cerrado' => ejecucion,
    _ => cuenta,
  };

  static CanalAviso? deCodigo(String codigo) {
    for (final c in values) {
      if (c.codigo == codigo) return c;
    }
    return null;
  }
}
