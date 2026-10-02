import '../../../nucleo/catalogo/motivo_retiro.dart';

/// Si se puede abrir una sesión NUEVA sobre un trabajo, y por qué no
/// (tarea 27). Dart puro: el repositorio lee de `drift` lo que hace falta y
/// [restriccionApertura] decide — mismo reparto que `reglas_condiciones.dart`.
///
/// No toca nada ya abierto: una sesión en curso se sigue y se cierra igual,
/// y el trabajo se cierra igual. Esto solo decide si el formulario de
/// apertura deja confirmar.
final class RestriccionApertura {
  const RestriccionApertura({this.bloqueo, this.aviso});

  static const ninguna = RestriccionApertura();

  /// Por qué no se puede abrir una sesión nueva, tal como lo lee el piloto;
  /// `null` si se puede.
  final String? bloqueo;

  /// Por qué el trabajo ya no está vigente en el catálogo, para mostrarlo en
  /// la pantalla de sesión; `null` si sigue vigente o no tiene fila en el
  /// catálogo. Solo informa: lo que bloquea va en [bloqueo].
  final String? aviso;

  bool get bloqueada => bloqueo != null;

  @override
  bool operator ==(Object other) =>
      other is RestriccionApertura &&
      other.bloqueo == bloqueo &&
      other.aviso == aviso;

  @override
  int get hashCode => Object.hash(bloqueo, aviso);
}

/// [haySesionAbierta]: si este dispositivo ya tiene una sesión abierta, en
/// cualquier trabajo. Nunca dos a la vez: la segunda se abre recién después
/// de cerrar la primera.
///
/// [motivoRetiroOrden]: `OrdenCatalogo.motivoRetiro` de la orden del
/// trabajo. Con `pausada` no se abre una sesión nueva — el servidor la
/// aceptaría, pero el dueño decidió que no se vuele sobre una orden
/// pausada.
///
/// [motivoRetiroTrabajo]: `TrabajoCatalogo.motivoRetiro`. Espejo de
/// `EscrituraSincronizacionEloquent::abrirSesion()` de `agrocom-api`, que
/// busca el trabajo sin los dados de baja y no mira ni su estado ni su
/// equipo:
/// - `dado_de_baja`: el servidor rechaza la sesión con
///   `trabajo_no_existe_aun`. Cargada sin señal, se perdería al
///   sincronizar, así que no se abre. Lo que ya estaba en curso sí se
///   registra: desde `agrocom-api` #314 (`add36c2b`) el servidor acepta el
///   cierre de la sesión, sus condiciones y el cierre del trabajo, y el
///   aviso lo dice.
/// - `reasignado`, `cerrado`, `orden_cerrada` y el local
///   `fuera_de_alcance`: el servidor la acepta, así que no se bloquea; solo
///   se avisa.
RestriccionApertura restriccionApertura({
  required bool haySesionAbierta,
  String? motivoRetiroOrden,
  String? motivoRetiroTrabajo,
}) {
  final aviso = switch (motivoRetiroTrabajo) {
    null => null,
    MotivoRetiro.dadoDeBaja =>
      'El trabajo fue dado de baja desde el panel: no se puede abrir una '
          'sesión nueva. La sesión abierta y el trabajo se cierran y se '
          'registran igual.',
    final motivo => MotivoRetiro.describirTrabajo(motivo),
  };
  final String? bloqueo;
  if (haySesionAbierta) {
    bloqueo =
        'Ya hay una sesión abierta en este dispositivo: volvé a ella desde '
        '«Inicio» y cerrala antes de abrir otra.';
  } else if (motivoRetiroTrabajo == MotivoRetiro.dadoDeBaja) {
    bloqueo =
        'El trabajo fue dado de baja desde el panel: no se puede abrir una '
        'sesión nueva. Podés cerrar el trabajo; se registra igual.';
  } else if (motivoRetiroOrden == MotivoRetiro.ordenPausada) {
    bloqueo =
        'La orden de este trabajo está pausada: no se vuela hasta que '
        'vuelva a estar vigente.';
  } else {
    bloqueo = null;
  }
  return RestriccionApertura(bloqueo: bloqueo, aviso: aviso);
}
