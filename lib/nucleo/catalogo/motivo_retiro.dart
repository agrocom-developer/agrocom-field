/// Motivos de retiro de una fila de catálogo que la app necesita nombrar
/// (tarea 26). El resto llega tal cual del servidor en
/// `ordenes_retiradas.estado` / `trabajos_retirados.motivo` de
/// `agrocom-api` #313 y se guarda como texto, sin interpretarlo.
abstract final class MotivoRetiro {
  /// Motivo LOCAL, nunca lo manda el servidor: la fila no llegó en un
  /// barrido completo (pull desde cursor vacío terminado sin error). Es como
  /// la app limpia lo que el servidor ya no le entrega pero que nunca va a
  /// llegar como retirado. Casos: filas de otros equipos bajadas antes de
  /// #312, y retiros anteriores a #313, porque con cursor vacío el servidor
  /// no manda retirados.
  static const fueraDeAlcance = 'fuera_de_alcance';

  /// `MotivoRetiroTrabajo::DadoDeBaja` de `agrocom-api`: baja lógica desde
  /// el panel. El único motivo en el que el servidor ya no encuentra el
  /// trabajo de una sesión y valida sus condiciones con los defaults del
  /// sistema.
  static const dadoDeBaja = 'dado_de_baja';

  /// `MotivoRetiroTrabajo::Reasignado`: el trabajo pasó a un equipo donde
  /// la persona no está vigente, o quedó sin equipo.
  static const reasignado = 'reasignado';

  /// `MotivoRetiroTrabajo::Cerrado`.
  static const cerrado = 'cerrado';

  /// `MotivoRetiroTrabajo::OrdenCerrada`: su orden pasó a `consumida`,
  /// `cancelada` o `vencida`.
  static const ordenCerrada = 'orden_cerrada';

  /// Estado `pausada` de `ordenes_retiradas` (tarea 27). El servidor no
  /// retira los trabajos de una orden pausada y acepta sesiones sobre
  /// ellos, pero el dueño decidió que la app no abra sesiones nuevas
  /// mientras la orden esté pausada.
  static const ordenPausada = 'pausada';

  /// Lo que ve el piloto para el motivo de retiro de un TRABAJO. Un motivo
  /// que la app no conoce se muestra tal cual, nunca se oculta.
  static String describirTrabajo(String motivo) => switch (motivo) {
    dadoDeBaja => 'El trabajo fue dado de baja desde el panel.',
    reasignado => 'El trabajo fue reasignado a otro equipo.',
    cerrado => 'El trabajo fue cerrado desde el panel.',
    ordenCerrada =>
      'La orden del trabajo se cerró (consumida, cancelada o vencida).',
    fueraDeAlcance => 'El trabajo ya no llega al catálogo de este dispositivo.',
    _ => 'El trabajo fue retirado del catálogo ($motivo).',
  };
}
