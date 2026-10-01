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
}
