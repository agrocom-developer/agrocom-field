/// Si se puede abrir una sesión NUEVA sobre un trabajo, y por qué no
/// (tarea 27). Dart puro: el repositorio lee de `drift` lo que hace falta y
/// [restriccionApertura] decide — mismo reparto que `reglas_condiciones.dart`.
///
/// No toca nada ya abierto: una sesión en curso se sigue y se cierra igual,
/// y el trabajo se cierra igual. Esto solo decide si el formulario de
/// apertura deja confirmar.
final class RestriccionApertura {
  const RestriccionApertura({this.bloqueo});

  static const ninguna = RestriccionApertura();

  /// Por qué no se puede abrir una sesión nueva, tal como lo lee el piloto;
  /// `null` si se puede.
  final String? bloqueo;

  bool get bloqueada => bloqueo != null;

  @override
  bool operator ==(Object other) =>
      other is RestriccionApertura && other.bloqueo == bloqueo;

  @override
  int get hashCode => bloqueo.hashCode;
}

/// [haySesionAbierta]: si este dispositivo ya tiene una sesión abierta, en
/// cualquier trabajo. Nunca dos a la vez: la segunda se abre recién después
/// de cerrar la primera.
RestriccionApertura restriccionApertura({required bool haySesionAbierta}) {
  if (haySesionAbierta) {
    return const RestriccionApertura(
      bloqueo:
          'Ya hay una sesión abierta en este dispositivo: volvé a ella desde '
          '«Inicio» y cerrala antes de abrir otra.',
    );
  }
  return RestriccionApertura.ninguna;
}
