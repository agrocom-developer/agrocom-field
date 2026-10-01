/// Lo que este dispositivo tiene en curso (tarea 27), para que el piloto
/// pueda volver a eso desde «Inicio» aunque haya salido de la pantalla de
/// sesión: una sesión abierta o, si no hay, un trabajo abierto con la
/// sesión ya cerrada.
///
/// Sale de `TrabajoLocal`/`SesionLocal` — lo que escribió el propio
/// dispositivo —, no de `TrabajoCatalogo`: se muestra aunque el trabajo esté
/// retirado del catálogo o lo haya abierto la app (sin fila en el
/// catálogo). Lo que viene por join con el catálogo (lote, motivo de
/// retiro) puede faltar.
///
/// Entidad Dart pura, testeable sin emulador (ADR 0005).
class TrabajoEnCurso {
  const TrabajoEnCurso({
    required this.trabajoUuidCliente,
    required this.inicio,
    this.sesionUuidCliente,
    this.loteCodigo,
    this.motivoRetiro,
  });

  /// El `uuid_cliente` del trabajo: con él se vuelve a la pantalla de
  /// sesión de ESE trabajo.
  final String trabajoUuidCliente;

  /// La sesión abierta, si la hay; `null` cuando solo queda el trabajo
  /// abierto.
  final String? sesionUuidCliente;

  /// Inicio de la sesión abierta o, sin sesión, del trabajo.
  final DateTime inicio;

  /// `LoteCatalogo.codigo`; `null` si el lote no llegó todavía.
  final String? loteCodigo;

  /// `TrabajoCatalogo.motivoRetiro`: `null` si el trabajo sigue vigente o si
  /// no tiene fila en el catálogo (lo abrió la app).
  final String? motivoRetiro;

  bool get conSesion => sesionUuidCliente != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrabajoEnCurso &&
          other.trabajoUuidCliente == trabajoUuidCliente &&
          other.sesionUuidCliente == sesionUuidCliente &&
          other.inicio == inicio &&
          other.loteCodigo == loteCodigo &&
          other.motivoRetiro == motivoRetiro);

  @override
  int get hashCode => Object.hash(
    trabajoUuidCliente,
    sesionUuidCliente,
    inicio,
    loteCodigo,
    motivoRetiro,
  );
}
