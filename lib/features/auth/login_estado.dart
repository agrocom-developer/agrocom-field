/// Estado de `LoginCubit` — pantalla simple, alcanza con inicial/cargando/
/// exitoso/error (ver HU-03: "estados inicial/cargando/error, así que
/// Cubit alcanza").
sealed class LoginEstado {
  const LoginEstado();
}

final class LoginInicial extends LoginEstado {
  const LoginInicial();
}

final class LoginCargando extends LoginEstado {
  const LoginCargando();
}

/// El widget que escucha este estado navega al placeholder — no hay nada
/// más que mostrar acá.
final class LoginExitosoEstado extends LoginEstado {
  const LoginExitosoEstado();
}

final class LoginFallido extends LoginEstado {
  const LoginFallido(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is LoginFallido && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
